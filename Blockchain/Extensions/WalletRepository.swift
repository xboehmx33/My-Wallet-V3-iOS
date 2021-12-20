// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import PlatformKit
import RxRelay
import RxSwift
import ToolKit
import WalletPayloadKit

// TODO: Remove `NSObject` when `Wallet` is killed
/// A bridge to `Wallet` since it is an ObjC object.
@objc
final class WalletRepository: NSObject, WalletRepositoryAPI, WalletCredentialsProviding {

    // MARK: - Types

    private enum JSSetter {

        enum Password {
            static let change = "MyWalletPhone.changePassword(\"%@\")"
            static let success = "objc_on_change_password_success"
            static let error = "objc_on_change_password_error"
        }

        /// Accepts "true" / "false" as parameter
        static let syncPubKeys = "MyWalletPhone.setSyncPubKeys(%@)"

        /// Accepts a String representing the language
        static let language = "MyWalletPhone.setLanguage(\"%@\")"

        /// Accepts a String representing the wallet payload
        static let payload = "MyWalletPhone.setEncryptedWalletData(\"%@\")"

        /// Fetches the user offline token
        static let offlineToken = "MyWalletPhone.KYC.lifetimeToken()"

        /// Fetches the user id
        static let userId = "MyWalletPhone.KYC.userId()"

        /// Updates user credentials: userId, lifetimeToken
        static let updateUserCredentials = "MyWalletPhone.KYC.updateUserCredentials(\"%@\", \"%@\")"
    }

    private enum JSCallback {
        static let updateUserCredentialsSuccess = "objc_updateUserCredentials_success"
        static let updateUserCredentialsFailure = "objc_updateUserCredentials_error"
    }

    // MARK: - Properties

    private let sessionTokenRelay = BehaviorRelay<String?>(value: nil)
    private let authenticatorTypeRelay = BehaviorRelay<WalletAuthenticatorType>(value: .standard)
    private let passwordRelay = BehaviorRelay<String?>(value: nil)
    private let reactiveWallet: ReactiveWalletAPI

    /// Streams the GUID if exists
    var guid: AnyPublisher<String?, Never> {
        .just(settings.guid)
    }

    /// Streams the cached shared key or `nil` if it is not cached
    var sharedKey: AnyPublisher<String?, Never> {
        .just(settings.sharedKey)
    }

    /// Streams the session token if exists
    var sessionToken: AnyPublisher<String?, Never> {
        sessionTokenRelay.take(1).asPublisher().ignoreFailure()
    }

    /// Streams the authenticator type
    var authenticatorType: AnyPublisher<WalletAuthenticatorType, Never> {
        authenticatorTypeRelay.take(1).asPublisher().ignoreFailure()
    }

    /// Streams the password if exists
    var password: AnyPublisher<String?, Never> {
        passwordRelay.take(1).asPublisher().ignoreFailure()
    }

    var hasPassword: AnyPublisher<Bool, Never> {
        password
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    /// Streans the nabu offline token
    var offlineToken: AnyPublisher<NabuOfflineToken, MissingCredentialsError> {
        let userId = userIdFromJS
        let offlineToken = offlineTokenFromJS
        return reactiveWallet.waitUntilInitializedSinglePublisher
            .mapError()
            .flatMap { [userId, offlineToken] _ -> AnyPublisher<(String?, String?), WalletError> in
                Publishers.Zip(
                    userId,
                    offlineToken
                )
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .replaceError(with: MissingCredentialsError.offlineToken)
            .flatMap { userId, offlineToken
                -> AnyPublisher<(userId: String, offlineToken: String, created: Bool?), MissingCredentialsError> in
                guard let userId = userId else {
                    return .failure(.userId)
                }
                guard let offlineToken = offlineToken else {
                    return .failure(.offlineToken)
                }
                return .just((userId: userId, offlineToken: offlineToken, created: nil))
            }
            .map(NabuOfflineToken.init)
            .eraseToAnyPublisher()
    }

    private var offlineTokenFromJS: AnyPublisher<String?, WalletError> {
        let jsContextProvider = jsContextProvider
        return Deferred {
            Future { [jsContextProvider] promise in
                guard WalletManager.shared.wallet.isInitialized() else {
                    promise(.failure(.notInitialized))
                    return
                }
                guard let jsValue = jsContextProvider
                    .jsContext
                    .evaluateScriptCheckIsOnMainQueue(JSSetter.offlineToken)
                else {
                    promise(.success(nil))
                    return
                }
                guard !jsValue.isNull, !jsValue.isUndefined else {
                    promise(.success(nil))
                    return
                }
                guard let string = jsValue.toString() else {
                    promise(.success(nil))
                    return
                }
                guard !string.isEmpty else {
                    promise(.success(nil))
                    return
                }
                promise(.success(string))
            }
        }
        .subscribe(on: combineJSScheduler)
        .eraseToAnyPublisher()
    }

    private var userIdFromJS: AnyPublisher<String?, WalletError> {
        let jsContextProvider = jsContextProvider
        return Deferred {
            Future { [jsContextProvider] promise in
                guard WalletManager.shared.wallet.isInitialized() else {
                    promise(.failure(.notInitialized))
                    return
                }
                guard let jsValue = jsContextProvider.jsContext.evaluateScriptCheckIsOnMainQueue(JSSetter.userId) else {
                    promise(.success(nil))
                    return
                }
                guard !jsValue.isNull, !jsValue.isUndefined else {
                    promise(.success(nil))
                    return
                }
                guard !jsValue.isNull, !jsValue.isUndefined else {
                    promise(.success(nil))
                    return
                }
                guard let string = jsValue.toString() else {
                    promise(.success(nil))
                    return
                }
                guard !string.isEmpty else {
                    promise(.success(nil))
                    return
                }
                promise(.success(string))
            }
        }
        .subscribe(on: combineJSScheduler)
        .eraseToAnyPublisher()
    }

    private let settings: AppSettingsAPI
    private let jsScheduler: SerialDispatchQueueScheduler
    private let combineJSScheduler: DispatchQueue
    private unowned let jsContextProvider: JSContextProviderAPI

    // MARK: - Setup

    init(
        jsContextProvider: JSContextProviderAPI,
        appSettings: AppSettingsAPI,
        reactiveWallet: ReactiveWalletAPI,
        jsScheduler: SerialDispatchQueueScheduler = MainScheduler.instance,
        combineJSScheduler: DispatchQueue = DispatchQueue.main
    ) {
        self.jsContextProvider = jsContextProvider
        settings = appSettings
        self.reactiveWallet = reactiveWallet
        self.jsScheduler = jsScheduler
        self.combineJSScheduler = combineJSScheduler
        super.init()
    }

    // MARK: - Wallet Setters

    /// Sets the guid
    func set(guid: String) -> AnyPublisher<Void, Never> {
        perform { [weak self] in
            self?.settings.guid = guid
        }
    }

    /// Sets the shared key
    func set(sharedKey: String) -> AnyPublisher<Void, Never> {
        perform { [weak self] in
            self?.settings.sharedKey = sharedKey
        }
    }

    /// Sets the session token
    func set(sessionToken: String) -> AnyPublisher<Void, Never> {
        perform { [weak sessionTokenRelay] in
            sessionTokenRelay?.accept(sessionToken)
        }
    }

    /// Clear the session token
    func cleanSessionToken() -> AnyPublisher<Void, Never> {
        perform { [weak sessionTokenRelay] in
            sessionTokenRelay?.accept(nil)
        }
    }

    /// Sets the authenticator type
    func set(authenticatorType: WalletAuthenticatorType) -> AnyPublisher<Void, Never> {
        perform { [weak authenticatorTypeRelay] in
            authenticatorTypeRelay?.accept(authenticatorType)
        }
    }

    /// Sets the password
    func set(password: String) -> AnyPublisher<Void, Never> {
        perform { [weak passwordRelay] in
            passwordRelay?.accept(password)
        }
    }

    // MARK: - JS Setters

    func set(language: String) -> AnyPublisher<Void, Never> {
        perform { [weak jsContextProvider] in
            let escaped = language.escapedForJS()
            let script = String(format: JSSetter.language, escaped)
            jsContextProvider?.jsContext.evaluateScriptCheckIsOnMainQueue(script)
        }
    }

    func set(syncPubKeys: Bool) -> AnyPublisher<Void, Never> {
        perform { [weak jsContextProvider] in
            let value = syncPubKeys ? "true" : "false"
            let script = String(format: JSSetter.syncPubKeys, value)
            jsContextProvider?.jsContext.evaluateScriptCheckIsOnMainQueue(script)
        }
    }

    func set(offlineToken: NabuOfflineToken) -> AnyPublisher<Void, CredentialWritingError> {
        let jsContextProvider = jsContextProvider
        return Deferred {
            Future { [jsContextProvider] promise in
                jsContextProvider.jsContext.invokeOnce(
                    functionBlock: {
                        promise(.failure(.offlineToken))
                    },
                    forJsFunctionName: JSCallback.updateUserCredentialsFailure as NSString
                )
                jsContextProvider.jsContext.invokeOnce(
                    functionBlock: {
                        promise(.success(()))
                    },
                    forJsFunctionName: JSCallback.updateUserCredentialsSuccess as NSString
                )
                let userId = offlineToken.userId.escapedForJS()
                let offlineToken = offlineToken.token.escapedForJS()
                let script = String(format: JSSetter.updateUserCredentials, userId, offlineToken)
                jsContextProvider.jsContext.evaluateScriptCheckIsOnMainQueue(script)?.toString()
            }
        }
        .subscribe(on: combineJSScheduler)
        .eraseToAnyPublisher()
    }

    func set(payload: String) -> AnyPublisher<Void, Never> {
        perform { [weak jsContextProvider] in
            let escaped = payload.escapedForJS()
            let script = String(format: JSSetter.payload, escaped)
            jsContextProvider?.jsContext.evaluateScriptCheckIsOnMainQueue(script)
        }
    }

    func sync() -> AnyPublisher<Void, PasswordRepositoryError> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(.syncFailed))
                    return
                }
                guard let password = self.passwordRelay.value else {
                    promise(.failure(.unavailable))
                    return
                }

                let script = String(format: JSSetter.Password.change, password)

                self.jsContextProvider.jsContext.invokeOnce(functionBlock: {
                    promise(.success(()))
                }, forJsFunctionName: JSSetter.Password.success as NSString)

                self.jsContextProvider.jsContext.invokeOnce(functionBlock: {
                    promise(.failure(.syncFailed))
                }, forJsFunctionName: JSSetter.Password.error as NSString)

                self.jsContextProvider.jsContext.evaluateScriptCheckIsOnMainQueue(script)
            }
        }
        .subscribe(on: combineJSScheduler)
        .eraseToAnyPublisher()
    }

    // MARK: - Accessors

    private func perform(_ operation: @escaping () -> Void) -> Completable {
        Completable
            .create { observer -> Disposable in
                operation()
                observer(.completed)
                return Disposables.create()
            }
            .subscribe(on: jsScheduler)
    }

    fileprivate func perform(_ operation: @escaping () -> Void) -> AnyPublisher<Void, Never> {
        Deferred {
            Future { promise in
                promise(.success(operation()))
            }
        }
        .subscribe(on: combineJSScheduler)
        .eraseToAnyPublisher()
    }

    fileprivate func perform<E: Error>(_ operation: @escaping () -> Void) -> AnyPublisher<Void, E> {
        let perform: AnyPublisher<Void, Never> = perform {
            operation()
        }
        return perform.mapError()
    }

    // MARK: - Legacy: PLEASE DONT USE THESE UNLESS YOU MUST HOOK LEGACY OBJ-C CODE

    @available(*, deprecated, message: "Please do not use this unless you absolutely need direct access")
    @objc
    var legacySessionToken: String? {
        get {
            sessionTokenRelay.value
        }
        set {
            sessionTokenRelay.accept(newValue)
        }
    }

    @available(*, deprecated, message: "Please do not use this unless you absolutely need direct access")
    @objc
    var legacyPassword: String? {
        get {
            passwordRelay.value
        }
        set {
            passwordRelay.accept(newValue)
        }
    }
}
