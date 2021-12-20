// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

final class BuyCryptoScreenPresenter: EnterAmountScreenPresenter {

    private struct CTAData {
        let kycState: KycState
        let isSimpleBuyEligible: Bool
        let candidateOrderDetails: CandidateOrderDetails
    }

    // MARK: - Properties

    private let stateService: CheckoutServiceAPI
    private let router: RouterAPI
    private let interactor: BuyCryptoScreenInteractor

    private let disposeBag = DisposeBag()

    private let featureFlagsService: FeatureFlagsServiceAPI

    init(
        router: RouterAPI,
        stateService: CheckoutServiceAPI,
        interactor: BuyCryptoScreenInteractor,
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.interactor = interactor
        self.stateService = stateService
        self.router = router
        self.featureFlagsService = featureFlagsService
        super.init(
            analyticsRecorder: analyticsRecorder,
            inputTypeToggleVisibility: .visible,
            backwardsNavigation: {
                stateService.previousRelay.accept(())
            },
            displayBundle: .buy,
            interactor: interactor
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        interactor.effect
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] effect in
                switch effect {
                case .failure(let error):
                    self?.handle(error)
                case .none:
                    break
                }
            })
            .disposed(by: disposeBag)

        topSelectionButtonViewModel.tap
            .emit(weak: self) { (self) in
                self.router.showCryptoSelectionScreen()
            }
            .disposed(by: disposeBag)

        // Payment Method Selection Button Setup

        Observable
            .combineLatest(
                interactor.preferredPaymentMethodType,
                interactor.paymentMethodTypes.map(\.count)
            )
            .observeOn(MainScheduler.asyncInstance)
            .do(onError: { [weak self] error in
                self?.handle(error)
            })
            .catchError { _ -> Observable<(PaymentMethodType?, Int)> in
                .empty()
            }
            .bindAndCatch(weak: self) { (self, payload) in
                self.setup(preferredPaymentMethodType: payload.0, methodCount: payload.1)
            }
            .disposed(by: disposeBag)

        /// Additional binding

        let ctaObservable = continueButtonTapped
            .asObservable()
            .withLatestFrom(interactor.candidateOrderDetails)
            .compactMap { $0 }
            .show(loader: loader, style: .circle)
            .flatMap(weak: self) { [loader, router, featureFlagsService] (self, candidateOrderDetails) -> Observable<Result<CTAData, Error>> in
                // Perform email verification and KYC checks to obtain a CTAData value used by
                let performKYCChecks: () -> Observable<Result<CTAData, Error>> = { [weak self] in
                    guard let self = self else {
                        return Observable.error(ToolKitError.nullReference(Self.self))
                    }
                    // TODO: present new KYC depending on feature flag (IOS-4471)
                    return self.performLegacyKYCCheck(for: candidateOrderDetails)
                }
                return featureFlagsService.isEnabled(.remote(.showEmailVerificationInBuyFlow))
                    .asObservable()
                    .flatMap { shouldShowEmailVerification -> Observable<Result<CTAData, Error>> in
                        guard shouldShowEmailVerification else {
                            return performKYCChecks()
                        }
                        return router.presentEmailVerificationIfNeeded()
                            .asObservable()
                            .flatMap { result -> Observable<Result<CTAData, Error>> in
                                switch result {
                                case .abandoned:
                                    // user abandoned EV, so don't show an error but hide the loader to let the user continue
                                    loader.hide()
                                    return Empty(
                                        completeImmediately: true,
                                        outputType: Result<CTAData, Error>.self,
                                        failureType: Error.self
                                    )
                                    .asObservable()
                                case .completed:
                                    return performKYCChecks()
                                }
                            }
                            .catchError { error in
                                .just(.failure(error))
                            }
                    }
            }
            .observeOn(MainScheduler.asyncInstance)
            .do(onError: { [weak self] error in
                self?.handle(error)
            })
            .catchError { error -> Observable<Result<CTAData, Error>> in
                .just(.failure(error))
            }
            .share()

        ctaObservable
            .compactMap { result -> CandidateOrderDetails? in
                guard case .success(let data) = result else { return nil }
                return data.candidateOrderDetails
            }
            .compactMap { [weak self] candidateOrderDetails in
                let paymentMethod = candidateOrderDetails.paymentMethod?.method
                return self?.displayBundle.events.confirmTapped(
                    candidateOrderDetails.fiatValue.currencyType,
                    candidateOrderDetails.fiatValue.moneyValue,
                    candidateOrderDetails.cryptoCurrency,
                    [AnalyticsEvents.SimpleBuy.ParameterName.paymentMethod: (paymentMethod?.analyticsParameter.string) ?? ""]
                )
            }
            .subscribe(onNext: { [weak self] events in
                self?.analyticsRecorder.record(events: events)
            })
            .disposed(by: disposeBag)

        ctaObservable
            .map(weak: self) { (self, result) -> AnalyticsEvent in
                switch result {
                case .success:
                    return self.displayBundle.events.confirmSuccess
                case .failure:
                    return self.displayBundle.events.confirmFailure
                }
            }
            .subscribe(onNext: analyticsRecorder.record(event:))
            .disposed(by: disposeBag)

        ctaObservable
            .observeOn(MainScheduler.instance)
            .bindAndCatch(weak: self) { (self, result) in
                switch result {
                case .success(let data):
                    switch (data.kycState, data.isSimpleBuyEligible) {
                    case (.completed, false):
                        self.loader.hide()
                        self.stateService.ineligible()
                    case (.completed, true):
                        self.createOrder(from: data.candidateOrderDetails) { [weak self] checkoutData in
                            self?.loader.hide()
                            self?.stateService.nextFromBuyCrypto(with: checkoutData)
                        }
                    case (.shouldComplete, _):
                        // This logic should only happen when performing legacy KYC checks
                        self.createOrder(from: data.candidateOrderDetails) { [weak self] checkoutData in
                            self?.loader.hide()
                            self?.stateService.kyc(with: checkoutData)
                        }
                    }
                case .failure(let error):
                    self.handle(error)
                }
            }
            .disposed(by: disposeBag)

        interactor.selectedCurrencyType
            .map { $0.cryptoCurrency! }
            .flatMap(weak: self) { (self, cryptoCurrency) -> Observable<String?> in
                self.subtitleForCryptoCurrencyPicker(cryptoCurrency: cryptoCurrency)
            }
            .observeOn(MainScheduler.asyncInstance)
            .do(onError: { [weak self] error in
                self?.handle(error)
            })
            .catchError { _ -> Observable<String?> in
                .just(nil)
            }
            .bindAndCatch(to: topSelectionButtonViewModel.subtitleRelay)
            .disposed(by: disposeBag)

        // Bind to the pairs the user is able to buy

        interactor.pairsCalculationState
            .handle(loadingViewPresenter: loader)
            .catchError { _ -> Observable<ValueCalculationState<SupportedPairs>> in
                .just(.invalid(ValueCalculationState<SupportedPairs>.CalculationError.valueCouldNotBeCalculated))
            }
            .bindAndCatch(weak: self) { (self, state) in
                guard case .invalid(let error) = state, error == .valueCouldNotBeCalculated else {
                    return
                }
                self.handle(error)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private methods

    private func createOrder(
        from candidateOrderDetails: CandidateOrderDetails,
        with completion: @escaping (CheckoutData) -> Void
    ) {
        interactor.createOrder(from: candidateOrderDetails)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: completion,
                onFailure: { [weak self] error in
                    self?.handle(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func subtitleForCryptoCurrencyPicker(cryptoCurrency: CryptoCurrency) -> Observable<String?> {
        guard deviceType != .superCompact else {
            return .just(nil)
        }
        return Observable
            .combineLatest(
                interactor.fiatCurrencyService.displayCurrencyPublisher.asObservable(),
                Observable.just(cryptoCurrency)
            )
            .flatMap(weak: self) { (self, currencies) -> Observable<(FiatValue, CryptoCurrency)> in
                let fiat = currencies.0
                let crypto = currencies.1
                return self.interactor.priceService.price(of: crypto, in: fiat)
                    .compactMap(\.moneyValue.fiatValue)
                    .map { (fiat: $0, crypto: crypto) }
                    .asObservable()
            }
            .map { payload -> String in
                let tuple: (fiat: FiatValue, crypto: CryptoCurrency) = payload
                return "1 \(tuple.crypto.displayCode) = \(tuple.fiat.displayString) \(tuple.fiat.displayCode)"
            }
            .catchError { _ -> Observable<String?> in
                .just(nil)
            }
    }

    private func setup(preferredPaymentMethodType: PaymentMethodType?, methodCount: Int) {
        let viewModel = SelectionButtonViewModel(with: preferredPaymentMethodType)
        if deviceType == .superCompact {
            viewModel.subtitleRelay.accept(nil)
        }

        let trailingImageViewContent: ImageViewContent
        // in case there's no preferredPaymentMethodType
        // but the payment methods count is greater than 1
        // we still need to allow the user to tap in order to show
        // the payment selection modal
        if methodCount > 1 {
            trailingImageViewContent = ImageViewContent(
                imageResource: .local(name: "icon-disclosure-small", bundle: .platformUIKit)
            )
            viewModel.isButtonEnabledRelay.accept(true)
        } else {
            trailingImageViewContent = .empty
            viewModel.isButtonEnabledRelay.accept(false)
        }

        viewModel.trailingContentRelay.accept(.image(trailingImageViewContent))

        viewModel.tap
            .emit(weak: self) { (self) in
                self.stateService.paymentMethods()
            }
            .disposed(by: disposeBag)

        bottomAuxiliaryViewModelStateRelay.accept(.selection(viewModel))
    }

    private func performLegacyKYCCheck(for candidateOrderDetails: CandidateOrderDetails) -> Observable<Result<CTAData, Error>> {
        Observable.zip(
            interactor.currentKycState.asObservable(),
            interactor.currentEligibilityState
        )
        .map { currentKycState, currentEligibilityState -> Result<CTAData, Error> in
            switch (currentKycState, currentEligibilityState) {
            case (.success(let kycState), .success(let isSimpleBuyEligible)):
                let ctaData = CTAData(
                    kycState: kycState,
                    isSimpleBuyEligible: isSimpleBuyEligible,
                    candidateOrderDetails: candidateOrderDetails
                )
                return .success(ctaData)
            case (.failure(let error), .success):
                return .failure(error)
            case (.success, .failure(let error)):
                return .failure(error)
            case (.failure(let error), .failure):
                return .failure(error)
            }
        }
    }
}
