// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import MoneyKit
import RxRelay
import RxSwift
import RxToolKit
import ToolKit

final class SettingsService: SettingsServiceAPI {

    // MARK: - Exposed Properties

    /// Streams the first available settings element
    var valueSingle: Single<WalletSettings> {
        valueObservable
            .take(1)
            .asSingle()
    }

    var valueObservable: Observable<WalletSettings> {
        settingsRelay
            .flatMap(weak: self) { (self, settings) -> Observable<WalletSettings> in
                guard let settings = settings else {
                    return self.fetch(force: false).asObservable()
                }
                return .just(settings)
            }
            .distinctUntilChanged()
    }

    // MARK: - Private Properties

    private let client: SettingsClientAPI
    private let credentialsRepository: CredentialsRepositoryAPI
    private let supportedPairsService: SupportedPairsServiceAPI

    private let settingsRelay = BehaviorRelay<WalletSettings?>(value: nil)
    private let disposeBag = DisposeBag()
    private let scheduler = SerialDispatchQueueScheduler(qos: .default)
    private let semaphore = DispatchSemaphore(value: 1)

    // MARK: - Setup

    init(
        client: SettingsClientAPI = resolve(),
        credentialsRepository: CredentialsRepositoryAPI = resolve(),
        supportedPairsService: SupportedPairsServiceAPI = resolve()
    ) {
        self.client = client
        self.credentialsRepository = credentialsRepository
        self.supportedPairsService = supportedPairsService

        NotificationCenter.when(.login) { [weak self] _ in
            self?.settingsRelay.accept(nil)
        }

        NotificationCenter.when(.logout) { [weak self] _ in
            self?.settingsRelay.accept(nil)
        }
    }

    // MARK: - Public Methods

    func fetch(force: Bool) -> Single<WalletSettings> {
        Single.create(weak: self) { (self, observer) -> Disposable in
            guard case .success = self.semaphore.wait(timeout: .now() + .seconds(30)) else {
                observer(.error(ToolKitError.timedOut))
                return Disposables.create()
            }
            let disposable = self.settingsRelay
                .take(1)
                .asSingle()
                .flatMap(weak: self) { (self, settings: WalletSettings?) -> Single<WalletSettings> in
                    self.fetchSettings(settings: settings, force: force)
                }
                .subscribe { event in
                    switch event {
                    case .success(let settings):
                        observer(.success(settings))
                    case .failure(let error):
                        observer(.error(error))
                    }
                }

            return Disposables.create {
                disposable.dispose()
                self.semaphore.signal()
            }
        }
        .subscribe(on: scheduler)
    }

    private func fetchSettings(settings: WalletSettings?, force: Bool) -> Single<WalletSettings> {
        guard force || settings == nil else { return Single.just(settings!) }
        return credentialsRepository.credentials.asSingle()
            .flatMap(weak: self) { (self, credentials) in
                self.client.settings(
                    by: credentials.guid,
                    sharedKey: credentials.sharedKey
                )
                .asSingle()
            }
            .map { WalletSettings(response: $0) }
            .do(onSuccess: { [weak self] settings in
                self?.settingsRelay.accept(settings)
            })
    }
}

extension SettingsService {

    // MARK: - SettingsServiceCombineAPI

    var singleValuePublisher: AnyPublisher<WalletSettings, SettingsServiceError> {
        valueSingle
            .asObservable()
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }

    var valuePublisher: AnyPublisher<WalletSettings, SettingsServiceError> {
        valueObservable
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchPublisher(force: Bool) -> AnyPublisher<WalletSettings, SettingsServiceError> {
        fetch(force: force)
            .asObservable()
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FiatCurrencySettingsServiceAPI

extension SettingsService: FiatCurrencySettingsServiceAPI {

    var displayCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        valueObservable
            .map { settings -> FiatCurrency in
                guard let currency = settings.displayCurrency else {
                    throw PlatformKitError.default
                }
                return currency
            }
            .distinctUntilChanged()
            .asPublisher()
            .replaceError(with: .USD)
            .eraseToAnyPublisher()
    }

    var tradingCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        valueObservable
            .distinctUntilChanged()
            .asPublisher()
            .flatMap { [displayCurrencyPublisher] settings -> AnyPublisher<FiatCurrency, Never> in
                guard let currency = settings.tradingCurrency else {
                    // fallback to the displayCurrency if a trading currency is not set
                    return displayCurrencyPublisher
                }
                return .just(currency)
            }
            .replaceError(with: .USD)
            .eraseToAnyPublisher()
    }

    var supportedFiatCurrencies: AnyPublisher<Set<FiatCurrency>, Never> {
        supportedPairsService
            .fetchSupportedTradingCurrencies()
            .replaceError(with: [.USD, .GBP, .USD])
            .eraseToAnyPublisher()
    }

    func update(displayCurrency: FiatCurrency, context: FlowContext) -> AnyPublisher<Void, CurrencyUpdateError> {
        let fetch = fetchPublisher(force: true)
        return credentialsRepository.credentials
            .mapError(CurrencyUpdateError.credentialsError)
            .flatMap { [client] (guid: String, sharedKey: String) in
                client.updatePublisher(
                    currency: displayCurrency.code,
                    context: context,
                    guid: guid,
                    sharedKey: sharedKey
                )
            }
            .zip(
                singleValuePublisher
                    .replaceError(with: CurrencyUpdateError.fetchError(SettingsServiceError.timedOut))
            )
            .flatMap { _, settings -> AnyPublisher<Void, CurrencyUpdateError> in
                fetch
                    .mapToVoid()
                    .mapError(CurrencyUpdateError.fetchError)
                    .handleEvents(
                        receiveSubscription: { _ in
                            // when setting the currency succeeds, clear the trading currency
                            // this way, the next time the trading currency is fetched, it will fallback to the new displayCurrency
                            settings.clearTradingCurrency()
                        }
                    )
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func update(tradingCurrency: FiatCurrency, context: FlowContext) -> AnyPublisher<Void, CurrencyUpdateError> {
        let fetch = fetchPublisher(force: true)
        return valueSingle
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .map { settings -> Void in
                settings.setTradingCurrency(to: tradingCurrency)
            }
            .mapError { error -> CurrencyUpdateError in
                CurrencyUpdateError.fetchError(SettingsServiceError.fetchFailed(error))
            }
            .flatMap { _ -> AnyPublisher<Void, CurrencyUpdateError> in
                fetch
                    .mapToVoid()
                    .mapError(CurrencyUpdateError.fetchError)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SettingsEmailUpdateServiceAPI

extension SettingsService: EmailSettingsServiceAPI {

    var email: Single<String> {
        valueSingle.map(\.email)
    }

    var emailPublisher: AnyPublisher<String, EmailSettingsServiceError> {
        valueSingle
            .map(\.email)
            .asPublisher()
            .mapError(EmailSettingsServiceError.unknown)
            .eraseToAnyPublisher()
    }

    func update(email: String, context: FlowContext?) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.update(
                    email: email,
                    context: context,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
    }

    func update(email: String) -> AnyPublisher<String, EmailSettingsServiceError> {
        credentialsRepository.credentials
            .mapError(EmailSettingsServiceError.credentialsError)
            .flatMap { [client] guid, sharedKey in
                client.update(
                    email: email,
                    context: nil,
                    guid: guid,
                    sharedKey: sharedKey
                )
                .mapError(EmailSettingsServiceError.networkError)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - LastTransactionSettingsUpdateServiceAPI

extension SettingsService: LastTransactionSettingsUpdateServiceAPI {
    func updateLastTransaction() -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.updateLastTransactionTime(
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - EmailNotificationSettingsServiceAPI

extension SettingsService: EmailNotificationSettingsServiceAPI {
    func emailNotifications(enabled: Bool) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.emailNotifications(
                    enabled: enabled,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - UpdateMobileSettingsServiceAPI

extension SettingsService: UpdateMobileSettingsServiceAPI {
    func update(mobileNumber: String) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.update(
                    smsNumber: mobileNumber,
                    context: .settings,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - VerifyMobileSettingsServiceAPI

extension SettingsService: VerifyMobileSettingsServiceAPI {
    func verify(with code: String) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.verifySMS(
                    code: code,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - SMSTwoFactorSettingsServiceAPI

extension SettingsService: SMSTwoFactorSettingsServiceAPI {
    func smsTwoFactorAuthentication(enabled: Bool) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.smsTwoFactorAuthentication(
                    enabled: enabled,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}
