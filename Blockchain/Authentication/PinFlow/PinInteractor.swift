// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureAuthenticationDomain
import PlatformKit
import RxSwift
import ToolKit
import WalletPayloadKit

/// Interactor for the pin. This component interacts with the Blockchain API and the local
/// pin data store. When the pin is updated, the pin is also stored on the keychain.
final class PinInteractor: PinInteracting {

    // MARK: - Type

    private enum Constant {
        enum IncorrectPinAlertLockTimeTrigger {
            /// 60 seconds lock time to trigger too many attempts alert
            static let tooManyAttempts = 60000
            /// 24 hours lock time to trigger cannot log in alert
            static let cannotLogin = 86400000
        }
    }

    // MARK: - Properties

    /// In case the user attempted to logout while the pin was being sent to the server
    /// the app needs to disragard any future response
    var hasLogoutAttempted = false

    private let pinClient: PinClientAPI
    private let maintenanceService: MaintenanceServicing
    private let credentialsProvider: WalletCredentialsProviding
    private let wallet: WalletProtocol
    private let appSettings: AppSettingsAuthenticating
    private let recorder: ErrorRecording
    private let cacheSuite: CacheSuite
    private let loginService: PinLoginServiceAPI
    private let walletCryptoService: WalletCryptoServiceAPI
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        credentialsProvider: WalletCredentialsProviding = WalletManager.shared.legacyRepository,
        pinClient: PinClientAPI = PinClient(),
        maintenanceService: MaintenanceServicing = resolve(),
        wallet: WalletProtocol = WalletManager.shared.wallet,
        appSettings: AppSettingsAuthenticating = resolve(),
        recorder: Recording = CrashlyticsRecorder(),
        cacheSuite: CacheSuite = resolve(),
        walletRepository: WalletRepositoryAPI = resolve(),
        walletCryptoService: WalletCryptoServiceAPI = resolve()
    ) {
        loginService = PinLoginService(
            settings: appSettings,
            service: DIKit.resolve()
        )
        self.credentialsProvider = credentialsProvider
        self.pinClient = pinClient
        self.maintenanceService = maintenanceService
        self.wallet = wallet
        self.appSettings = appSettings
        self.recorder = recorder
        self.cacheSuite = cacheSuite
        self.walletCryptoService = walletCryptoService
    }

    // MARK: - API

    // TODO: Re-enable this once we have isolated the source of the crash
    //    func serverStatus() -> Observable<ServerIncidents> {
    //        maintenanceService.serverStatus
    //            .filter { $0.hasActiveMajorIncident }
    //            .asObservable()
    //            .catchError { [weak self] (error) -> Observable<ServerIncidents> in
    //                self?.recorder.error(error)
    //                return .empty()
    //            }
    //    }

    /// Creates a pin code in the remote pin store
    /// - Parameter payload: the pin payload
    /// - Returns: Completable indicating completion
    func create(using payload: PinPayload) -> Completable {
        maintenanceService.serverUnderMaintenanceMessage
            .flatMap(weak: self) { (self, message) -> Single<PinStoreResponse> in
                if let message = message { throw PinError.serverMaintenance(message: message) }
                return self.pinClient.create(pinPayload: payload).asSingle()
            }
            .flatMapCompletable(weak: self) { (self, response) in
                self.handleCreatePinResponse(response: response, payload: payload)
            }
            .catchError { error in
                throw PinError.map(from: error)
            }
            .observeOn(MainScheduler.instance)
    }

    /// Validates if the provided pin payload (i.e. pin code and pin key combination) is correct.
    /// Calling this method will also fetch the WalletOptions to see if the server is under maintenance,
    /// then, handle updating the local pin store (i.e. the keychain),
    /// depending on the response for the remote pin store.
    /// - Parameter payload: the pin payload
    /// - Returns: Single warpping the pin decryption key
    func validate(using payload: PinPayload) -> Single<String> {
        maintenanceService.serverUnderMaintenanceMessage
            .flatMap(weak: self) { (self, message) -> Single<PinStoreResponse> in
                if let message = message { throw PinError.serverMaintenance(message: message) }
                return self.pinClient.validate(pinPayload: payload).asSingle()
            }
            .do(
                onSuccess: { [weak self] response in
                    guard let self = self else { return }
                    try self.updateCacheIfNeeded(response: response, pinPayload: payload)
                }
            )
            .map { [weak self] response -> String in
                guard let self = self else { throw PinError.unretainedSelf }
                return try self.pinValidationStatus(from: response)
            }
            .catchError { error in
                if let response = error as? PinStoreResponse {
                    // TODO: Check for invalid numerical value error by string comparison for now, should revisit when backend make necessary changes
                    if let error = response.error,
                       error.contains("Invalid Numerical Value")
                    {
                        throw PinError.invalid
                    }
                    let pinError = response.toPinError()
                    switch pinError {
                    case .incorrectPin(let message, let remaining, _):
                        let pinAlert = self.getPinAlertIfNeeded(remaining)
                        throw PinError.incorrectPin(message, remaining, pinAlert)
                    case .backoff(let message, let remaining, _):
                        let pinAlert = self.getPinAlertIfNeeded(remaining)
                        throw PinError.backoff(message, remaining, pinAlert)
                    default:
                        throw pinError
                    }
                } else {
                    throw PinError.map(from: error)
                }
            }
            .observeOn(MainScheduler.instance)
    }

    func password(from pinDecryptionKey: String) -> Single<String> {
        loginService.password(from: pinDecryptionKey)
            .observeOn(MainScheduler.instance)
    }

    /// Keep the PIN value on the local pin store (i.e the keychain), for biometrics auth.
    /// - Parameter pin: the pin value
    func persist(pin: Pin) {
        pin.save(using: appSettings)
        appSettings.biometryEnabled = true
    }

    // MARK: - Accessors

    private func getPinAlertIfNeeded(_ remaining: Int) -> PinError.PinAlert? {
        switch remaining {
        case Constant.IncorrectPinAlertLockTimeTrigger.tooManyAttempts:
            return .tooManyAttempts
        case let time where time >= Constant.IncorrectPinAlertLockTimeTrigger.cannotLogin:
            return .cannotLogin
        default:
            return nil
        }
    }

    private func handleCreatePinResponse(response: PinStoreResponse, payload: PinPayload) -> Completable {
        Single<(pin: String, password: String)>
            .create(weak: self) { (self, observer) -> Disposable in
                // Wallet must have password at the stage
                guard let password = self.credentialsProvider.legacyPassword else {
                    let error = PinError.serverError(LocalizationConstants.Pin.cannotSaveInvalidWalletState)
                    self.recorder.error(error)
                    observer(.error(error))
                    return Disposables.create()
                }

                guard response.error == nil else {
                    self.recorder.error(PinError.serverError(""))
                    observer(.error(PinError.serverError(response.error!)))
                    return Disposables.create()
                }

                guard response.isSuccessful else {
                    let message = String(
                        format: LocalizationConstants.Errors.invalidStatusCodeReturned,
                        response.statusCode?.rawValue ?? -1
                    )
                    let error = PinError.serverError(message)
                    self.recorder.error(error)
                    observer(.error(error))
                    return Disposables.create()
                }

                guard let pinValue = payload.pinValue,
                      !payload.pinKey.isEmpty,
                      !pinValue.isEmpty
                else {
                    let error = PinError.serverError(LocalizationConstants.Pin.responseKeyOrValueLengthZero)
                    self.recorder.error(error)
                    observer(.error(error))
                    return Disposables.create()
                }
                observer(.success((pin: pinValue, password: password)))
                return Disposables.create()
            }
            .flatMap(weak: self) { (self, data) -> Single<(encryptedPinPassword: String, password: String)> in
                self.walletCryptoService
                    .encrypt(
                        pair: KeyDataPair(key: data.pin, data: data.password),
                        pbkdf2Iterations: WalletCryptoPBKDF2Iterations.pinLogin
                    )
                    .map { (encryptedPinPassword: $0, password: data.password) }
            }
            .flatMapCompletable(weak: self) { (self, data) -> Completable in
                // Once the pin has been created successfully, the wallet is not longer marked as new.
                self.wallet.isNew = false
                // Update the cache
                self.appSettings.encryptedPinPassword = data.encryptedPinPassword
                self.appSettings.pinKey = payload.pinKey
                self.appSettings.passwordPartHash = data.password.passwordPartHash
                try self.updateCacheIfNeeded(response: response, pinPayload: payload)
                return Completable.empty()
            }
    }

    /// Persists the pin if needed or deletes it according to the response code received from the backend
    private func updateCacheIfNeeded(
        response: PinStoreResponse,
        pinPayload: PinPayload
    ) throws {
        // Make sure the user has not logout
        guard !hasLogoutAttempted else {
            throw PinError.receivedResponseWhileLoggedOut
        }

        guard let responseCode = response.statusCode else { return }
        switch responseCode {
        case .success where pinPayload.persistsLocally:
            // Optionally save the pin to the keychain to enable biometric authenticators
            persist(pin: pinPayload.pin!)
        case .deleted:
            // Clear pin from keychain if the user exceeded the number of retries when entering the pin.
            appSettings.pin = nil
            appSettings.biometryEnabled = false
        default:
            break
        }
    }

    // Returns the pin decryption key, or throws error if cannot
    private func pinValidationStatus(from response: PinStoreResponse) throws -> String {

        // TODO: Check for invalid numerical value error by string comparison for now, should revisit when backend make necessary changes
        if let error = response.error, error.contains("Invalid Numerical Value") {
            throw PinError.invalid
        }

        // Verify that the status code was received
        guard let statusCode = response.statusCode else {
            let error = PinError.serverError(LocalizationConstants.Errors.genericError)
            recorder.error(error)
            throw error
        }

        switch statusCode {
        case .success:
            guard let pinDecryptionKey = response.pinDecryptionValue, !pinDecryptionKey.isEmpty else {
                throw PinError.custom(LocalizationConstants.Errors.genericError)
            }
            return pinDecryptionKey
        case .deleted:
            throw PinError.tooManyAttempts
        case .incorrect:
            guard let remaining = response.remaining else {
                fatalError("Incorrect PIN should have an remaining field")
            }
            let message = LocalizationConstants.Pin.incorrect
            throw PinError.incorrectPin(message, remaining, nil)
        case .backoff:
            guard let remaining = response.remaining else {
                fatalError("Backoff should have an remaining field")
            }
            let message = LocalizationConstants.Pin.backoff
            throw PinError.backoff(message, remaining, nil)
        case .duplicateKey, .unknown:
            throw PinError.custom(LocalizationConstants.Errors.genericError)
        }
    }
}
