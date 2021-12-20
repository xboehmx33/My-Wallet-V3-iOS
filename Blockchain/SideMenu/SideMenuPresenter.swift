// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift
import ToolKit

/// Presenter for the side menu of the app. This presenter
/// will handle the logic as to what side menu items should be
/// presented in the SideMenuView.
class SideMenuPresenter {

    // MARK: Public Properties

    var sideMenuItems: AnyPublisher<[SideMenuItem], Never> {
        reactiveWallet
            .waitUntilInitializedSinglePublisher
            .flatMap { [menuItems] _ -> AnyPublisher<[SideMenuItem], Never> in
                menuItems
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var sideMenuFooterItems: AnyPublisher<(top: SideMenuItem, bottom: SideMenuItem), Never> {
        .just((top: .secureChannel, bottom: .logout))
    }

    var itemSelection: Signal<SideMenuItem> {
        itemSelectionRelay.asSignal()
    }

    // MARK: - Private Properties

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(
                .remote(.interestWithdrawAndDeposit)
            )
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private var menuItems: AnyPublisher<[SideMenuItem], Never> {
        isInterestWithdrawAndDepositEnabled
            .receive(on: DispatchQueue.main)
            .map { interestWithdrawDepositIsEnabled -> [SideMenuItem] in
                var items: [SideMenuItem] = []

                if interestWithdrawDepositIsEnabled {
                    items.append(.interest)
                }

                items += [
                    .accountsAndAddresses,
                    .buy,
                    .sell,
                    .support,
                    .airdrops,
                    .settings,
                    .exchange
                ]
                return items
            }
            .eraseToAnyPublisher()
    }

    private let featureFlagsService: FeatureFlagsServiceAPI
    private let itemSelectionRelay = PublishRelay<SideMenuItem>()

    // MARK: - Services

    private let wallet: Wallet
    private let walletService: WalletOptionsAPI
    private let reactiveWallet: ReactiveWalletAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let disposeBag = DisposeBag()
    private var disposable: Disposable?

    // MARK: - Init

    init(
        wallet: Wallet = WalletManager.shared.wallet,
        walletService: WalletOptionsAPI = resolve(),
        reactiveWallet: ReactiveWalletAPI = WalletManager.shared.reactiveWallet,
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        onboardingSettings: OnboardingSettings = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.wallet = wallet
        self.walletService = walletService
        self.reactiveWallet = reactiveWallet
        self.featureFlagsService = featureFlagsService
        self.analyticsRecorder = analyticsRecorder
    }

    deinit {
        disposable?.dispose()
        disposable = nil
    }

    /// The only reason this is here is for handling the pulse that
    /// is displayed on `buyBitcoin`.
    func onItemSelection(_ item: SideMenuItem) {
        itemSelectionRelay.accept(item)
    }
}
