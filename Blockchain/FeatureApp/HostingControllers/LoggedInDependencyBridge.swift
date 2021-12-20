// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureDashboardUI
import FeatureInterestUI
import FeatureSettingsUI
import PlatformUIKit

// These protocols are added here for simplicity,
// these are adopted both by `LoggedInHostingController` and `AppCoordinator`
// The methods and properties provided by these protocol where used by accessing the `.shared` property of AppCoordinator

/// Provides the ability to start a backup flow
protocol BackupFlowStarterAPI: AnyObject {
    func startBackupFlow()
}

/// Provides the ability to show settings
protocol SettingsStarterAPI: AnyObject {
    func showSettingsView()
}

/// Provides a reload mechanism that `Wallet` triggers
protocol LoggedInReloadAPI: AnyObject {
    func reload()
}

/// This protocol conforms to a set of certain protocols that were used as part of the
/// older `AppCoordinator` class which was passed around using it's `shared` property
/// This attempts to bridge the two worlds of the `LoggedInHostingController` and any
/// class that uses the extended protocols.
protocol LoggedInBridge: DrawerRouting,
    TabSwapping,
    CashIdentityVerificationAnnouncementRouting,
    InterestIdentityVerificationAnnouncementRouting,
    AppCoordinating,
    WalletOperationsRouting,
    BackupFlowStarterAPI,
    SettingsStarterAPI,
    LoggedInReloadAPI,
    InterestAccountListHostingControllerDelegate,
    AuthenticationCoordinating,
    QRCodeScannerRouting,
    ExternalActionsProviderAPI {}

protocol LoggedInDependencyBridgeAPI: AnyObject {
    /// Registers the bridge
    func register(bridge: LoggedInBridge)
    /// Unregisters the bridge
    func unregister()

    /// Provides `BackupFlowStarterAPI` methods
    func resolveBackupFlowStarter() -> BackupFlowStarterAPI

    /// Provides `SettingsStarterAPI` methods
    func resolveSettingsStarter() -> SettingsStarterAPI

    /// Provides `LoggedInReloadAPI` methods
    func resolveLoggedInReload() -> LoggedInReloadAPI

    /// Provides `DrawerRouting` methods
    func resolveDrawerRouting() -> DrawerRouting
    /// Provides `TabSwapping` methods
    func resolveTabSwapping() -> TabSwapping
    /// Provides `CashIdentityVerificationAnnouncementRouting` methods
    func resolveCashIdentityVerificationAnnouncementRouting() -> CashIdentityVerificationAnnouncementRouting
    /// Provides `InterestIdentityVerificationAnnouncementRouting` methods
    func resolveInterestIdentityVerificationAnnouncementRouting() -> InterestIdentityVerificationAnnouncementRouting
    /// Provides `AppCoordinating` methods
    func resolveAppCoordinating() -> AppCoordinating
    /// Provides `WalletOperationsRouting` methods
    func resolveWalletOperationsRouting() -> WalletOperationsRouting
    /// Provides `AuthenticationCoordinating` methods
    func resolveAuthenticationCoordinating() -> AuthenticationCoordinating
    /// Proves `QRCodeScannerRouting` methods
    func resolveQRCodeScannerRouting() -> QRCodeScannerRouting
    /// Provides logout
    func resolveExternalActionsProvider() -> ExternalActionsProviderAPI
}

final class LoggedInDependencyBridge: LoggedInDependencyBridgeAPI {

    private weak var hostingControllerBridge: LoggedInBridge?

    init() {}

    func register(bridge: LoggedInBridge) {
        hostingControllerBridge = bridge
    }

    func unregister() {
        hostingControllerBridge = nil
    }

    func resolveBackupFlowStarter() -> BackupFlowStarterAPI {
        resolve() as BackupFlowStarterAPI
    }

    func resolveSettingsStarter() -> SettingsStarterAPI {
        resolve() as SettingsStarterAPI
    }

    func resolveLoggedInReload() -> LoggedInReloadAPI {
        resolve() as LoggedInReloadAPI
    }

    func resolveDrawerRouting() -> DrawerRouting {
        resolve() as DrawerRouting
    }

    func resolveTabSwapping() -> TabSwapping {
        resolve() as TabSwapping
    }

    func resolveCashIdentityVerificationAnnouncementRouting() -> CashIdentityVerificationAnnouncementRouting {
        resolve() as CashIdentityVerificationAnnouncementRouting
    }

    func resolveInterestIdentityVerificationAnnouncementRouting() -> InterestIdentityVerificationAnnouncementRouting {
        resolve() as InterestIdentityVerificationAnnouncementRouting
    }

    func resolveAppCoordinating() -> AppCoordinating {
        resolve() as AppCoordinating
    }

    func resolveWalletOperationsRouting() -> WalletOperationsRouting {
        resolve() as WalletOperationsRouting
    }

    func resolveAuthenticationCoordinating() -> AuthenticationCoordinating {
        resolve() as AuthenticationCoordinating
    }

    func resolveQRCodeScannerRouting() -> QRCodeScannerRouting {
        resolve() as QRCodeScannerRouting
    }

    func resolveExternalActionsProvider() -> ExternalActionsProviderAPI {
        resolve() as ExternalActionsProviderAPI
    }

    /// Resolves the underlying bridge with a type
    /// - precondition: The bridge should conform to the type
    /// - Returns: The underlying bridge as a specific protocol type
    private func resolve<T>() -> T {
        precondition(hostingControllerBridge != nil, "No bridge detected, please first use register(bridge:) method")
        precondition(hostingControllerBridge is T, "Bridge does not conform to \(T.self) protocol")
        return hostingControllerBridge as! T
    }
}
