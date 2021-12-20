// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureKYCDomain
import MoneyKit
import PlatformKit
import class PlatformUIKit.AnnouncementRecorder
import RxRelay
import RxSwift
import ToolKit

public protocol KeychainItemWrapping {
    func pinFromKeychain() -> String?
    func removePinFromKeychain()
    func setPINInKeychain(_ pin: String?)

    func guid() -> String?
    func removeGuidFromKeychain()
    func setGuidInKeychain(_ guid: String?)

    func sharedKey() -> String?
    func removeSharedKeyFromKeychain()
    func setSharedKeyInKeychain(_ sharedKey: String?)

    func removeAllSwipeAddresses()
}

public protocol LegacyPasswordProviding: AnyObject {
    func setLegacyPassword(_ legacyPassword: String?)
}

public protocol AppSettingsBaseAPI: AnyObject {
    func reset()
}

public protocol SymbolLocalSettingsAPI: AnyObject {
    var onSymbolLocalChanged: ((Bool) -> Void)? { get set }

    /// Property indicating whether or not the currency symbol that should be used throughout the app
    /// should be fiat, if set to true, or the asset-specific symbol, if false.
    var symbolLocal: Bool { get set }
}

public typealias BlockchainSettingsAppAPI = AppSettingsAPI
    & AppSettingsAuthenticating
    & AppSettingsSecureChannel
    & CloudBackupConfiguring
    & PermissionSettingsAPI
    & SymbolLocalSettingsAPI
    & AppSettingsBaseAPI

/**
 Settings for the current user.
 All settings are written and read from NSUserDefaults.
 */
@objc
public final class BlockchainSettings: NSObject {

    // MARK: - App

    @objc(BlockchainSettingsApp)
    public final class App: NSObject, BlockchainSettingsAppAPI {

        @Inject @objc public static var shared: App

        @LazyInject private var defaults: CacheSuite

        public var isPairedWithWallet: Bool {
            guid != nil
                && sharedKey != nil
                && pinKey != nil
                && encryptedPinPassword != nil
        }

        // MARK: - Properties

        public var didRequestCameraPermissions: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didRequestCameraPermissions.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didRequestCameraPermissions.rawValue)
            }
        }

        public var didRequestMicrophonePermissions: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didRequestMicrophonePermissions.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didRequestMicrophonePermissions.rawValue)
            }
        }

        public var didRequestNotificationPermissions: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didRequestNotificationPermissions.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didRequestNotificationPermissions.rawValue)
            }
        }

        /**
         Stores the encrypted wallet password.

         - Note:
         The value of this setting is the result of calling the `encrypt(_ data: String, password: String)` function of the wallet.

         - Important:
         The encryption key is generated from the pin created by the user.
         legacyEncryptedPinPassword is required for wallets that created a PIN prior to Homebrew release - see IOS-1537
         */
        public var encryptedPinPassword: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.encryptedPinPassword.rawValue) ??
                    defaults.string(forKey: UserDefaults.Keys.legacyEncryptedPinPassword.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.encryptedPinPassword.rawValue)
                defaults.set(nil, forKey: UserDefaults.Keys.legacyEncryptedPinPassword.rawValue)
            }
        }

        @objc
        public var hasEndedFirstSession: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.hasEndedFirstSession.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.hasEndedFirstSession.rawValue)
            }
        }

        public var pin: String? {
            get {
                keychainItemWrapper.pinFromKeychain()
            }
            set {
                guard let pin = newValue else {
                    keychainItemWrapper.removePinFromKeychain()
                    return
                }
                keychainItemWrapper.setPINInKeychain(pin)
            }
        }

        public var pinKey: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.pinKey.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.pinKey.rawValue)
            }
        }

        public var onSymbolLocalChanged: ((Bool) -> Void)?

        /// Property indicating whether or not the currency symbol that should be used throughout the app
        /// should be fiat, if set to true, or the asset-specific symbol, if false.
        @objc
        public var symbolLocal: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.symbolLocal.rawValue)
            }
            set {
                let oldValue = symbolLocal

                defaults.set(newValue, forKey: UserDefaults.Keys.symbolLocal.rawValue)

                if oldValue != newValue {
                    onSymbolLocalChanged?(newValue)
                }
            }
        }

        /// The first 5 characters of SHA256 hash of the user's password
        public var passwordPartHash: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.passwordPartHash.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.passwordPartHash.rawValue)
            }
        }

        /**
         Keeps track if the user has elected to use biometric authentication in the application.

         - Note:
         This setting should be **deprecated** in the future, as we should always assume a user
         wants to use this feature if it is enabled system-wide.

         - SeeAlso:
         [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/user-interaction/authentication)
         */
        public var biometryEnabled: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.biometryEnabled.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.biometryEnabled.rawValue)
            }
        }

        @objc
        public var guid: String? {
            get {
                keychainItemWrapper.guid()
            }
            set {
                guard let guid = newValue else {
                    keychainItemWrapper.removeGuidFromKeychain()
                    return
                }
                keychainItemWrapper.setGuidInKeychain(guid)
            }
        }

        @objc
        public var sharedKey: String? {
            get {
                keychainItemWrapper.sharedKey()
            }
            set {
                guard let sharedKey = newValue else {
                    keychainItemWrapper.removeSharedKeyFromKeychain()
                    return
                }
                keychainItemWrapper.setSharedKeyInKeychain(sharedKey)
            }
        }

        /**
         Determines if the application should back up credentials to iCloud.

         - Note:
         The value of this setting is controlled by a switch on the settings screen.

         The default of this setting is `true`.
         */
        public var cloudBackupEnabled: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.cloudBackupEnabled.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.cloudBackupEnabled.rawValue)
            }
        }

        public var deviceKey: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.secureChannelDeviceKey.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.secureChannelDeviceKey.rawValue)
            }
        }

        public var browserIdentities: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.secureChannelBrowserIdentities.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.secureChannelBrowserIdentities.rawValue)
            }
        }

        /**
         Determines the number of labeled addresses for the default account.
         - Note:
         This value is set when the wallet has gotten its latest multi-address response.
         This setting is currently only used in the `didGet(_ response: MultiAddressResponse)` function of the wallet manager.
         */
        @objc
        public var defaultAccountLabelledAddressesCount: Int {
            get {
                defaults.integer(forKey: UserDefaults.Keys.defaultAccountLabelledAddressesCount.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.defaultAccountLabelledAddressesCount.rawValue)
            }
        }

        /**
         Determines if the user deep linked into the app using the airdrop dynamic link. This value is used in various
         places to handle the airdrop flow (e.g. prompt the user to KYC to finish the airdrop, to continue KYC'ing if
         they have already gone through the KYC flow, etc.)

         - Important:
         This setting **MUST** be set to `false` upon logging the user out of the application.
         */
        @objc
        public var didTapOnAirdropDeepLink: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didTapOnAirdropDeepLink.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didTapOnAirdropDeepLink.rawValue)
            }
        }

        /// Determines if the app already tried to route the user for the airdrop flow as a result
        /// of tapping on a deep link
        public var didAttemptToRouteForAirdrop: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didAttemptToRouteForAirdrop.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didAttemptToRouteForAirdrop.rawValue)
            }
        }

        /// Users that are linking their Exchange account to their blockchain wallet will deep-link
        /// from the Exchange into the mobile app.
        public var exchangeLinkIdentifier: String? {
            get {
                defaults.string(forKey: UserDefaults.Keys.exchangeLinkIdentifier.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.exchangeLinkIdentifier.rawValue)
            }
        }

        public var didTapOnExchangeDeepLink: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.didTapOnExchangeDeepLink.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.didTapOnExchangeDeepLink.rawValue)
            }
        }

        @objc
        public var custodySendInterstitialViewed: Bool {
            get {
                defaults.bool(forKey: UserDefaults.Keys.custodySendInterstitialViewed.rawValue)
            }
            set {
                defaults.set(newValue, forKey: UserDefaults.Keys.custodySendInterstitialViewed.rawValue)
            }
        }

        private var buySellCache: EventCache {
            resolve()
        }

        private var fiatSettings: FiatCurrencySettingsServiceAPI {
            resolve()
        }

        private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
        private let legacyPasswordProvider: LegacyPasswordProviding
        private let keychainItemWrapper: KeychainItemWrapping

        public init(
            enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
            keychainItemWrapper: KeychainItemWrapping = resolve(),
            legacyPasswordProvider: LegacyPasswordProviding = resolve()
        ) {
            self.enabledCurrenciesService = enabledCurrenciesService
            self.legacyPasswordProvider = legacyPasswordProvider
            self.keychainItemWrapper = keychainItemWrapper

            super.init()

            defaults.register(defaults: [
                UserDefaults.Keys.cloudBackupEnabled.rawValue: true
            ])
            migratePasswordAndPinIfNeeded()
            handleMigrationIfNeeded()
        }

        // MARK: - Public

        /**
         Resets app-specific settings back to their initial value.
         - Note:
         This function will not reset any settings which are derived from wallet options.
         */
        public func reset() {
            // TICKET: IOS-1365 - Finish UserDefaults refactor (tickets, documentation, linter issues)
            // TODO: - reset all appropriate settings upon logging out
            clearPin()
            custodySendInterstitialViewed = false
            didTapOnAirdropDeepLink = false
            didTapOnExchangeDeepLink = false
            didAttemptToRouteForAirdrop = false
            exchangeLinkIdentifier = nil

            let kycSettings: KYCSettingsAPI = resolve()
            kycSettings.reset()
            AnnouncementRecorder.reset()

            buySellCache.reset()

            Logger.shared.info("Application settings have been reset.")
        }

        /// - Warning: Calling This function will remove **ALL** settings in the application.
        public func clear() {
            UserDefaults.standard.removePersistentDomain(forName: MainBundleProvider.mainBundle.bundleIdentifier!)
            Logger.shared.info("Application settings have been cleared.")
        }

        public func clearPin() {
            pin = nil
            encryptedPinPassword = nil
            pinKey = nil
            passwordPartHash = nil
        }

        /// Migrates pin and password from NSUserDefaults to the Keychain
        public func migratePasswordAndPinIfNeeded() {
            guard let password = defaults.string(forKey: UserDefaults.Keys.password.rawValue),
                  let pinStr = defaults.string(forKey: UserDefaults.Keys.pin.rawValue),
                  let pinUInt = UInt(pinStr)
            else {
                return
            }

            legacyPasswordProvider.setLegacyPassword(password)

            Pin(code: pinUInt).save(using: self)

            defaults.removeObject(forKey: UserDefaults.Keys.password.rawValue)
            defaults.removeObject(forKey: UserDefaults.Keys.pin.rawValue)
        }

        //: Handles settings migration when keys change
        public func handleMigrationIfNeeded() {
            defaults.migrateLegacyKeysIfNeeded()
        }
    }
}
