//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAppUI
import FeatureAuthenticationDomain
import FeatureDashboardUI
import FeatureOnboardingUI
import FeatureTransactionUI
import FeatureWalletConnectDomain
import PlatformKit
import PlatformUIKit
import SwiftUI
import ToolKit

final class RootViewController: UIHostingController<RootView> {

    let viewStore: ViewStore<RootViewState, RootViewAction>

    var defaults: CacheSuite = UserDefaults.standard
    var send: (LoggedIn.Action) -> Void
    var bag: Set<AnyCancellable> = []

    init(store global: Store<LoggedIn.State, LoggedIn.Action>) {

        NotificationCenter.default.publisher(for: .transaction)
            .prefix(1)
            .delay(for: .seconds(1), scheduler: RunLoop.main, options: .none)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                StoreReviewController.requestReview()
            }
            .store(in: &bag)

        send = ViewStore(global).send

        let environment = RootViewEnvironment()
        let store = Store(
            initialState: RootViewState(
                fab: .init(
                    animate: !defaults.hasInteractedWithFrequentActionButton
                )
            ),
            reducer: rootViewReducer,
            environment: environment
        )

        viewStore = ViewStore(store)

        super.init(rootView: RootView(store: store))

        subscribe(to: ViewStore(global))

        if !defaults.hasInteractedWithFrequentActionButton {
            environment.publisher
                .map(\.state.fab.isOn)
                .first(where: \.self)
                .sink(to: My.handleFirstFrequentActionButtonInteraction, on: self)
                .store(in: &bag)
        }

        environment.publisher
            .sink(to: My.handle(state:action:), on: self)
            .store(in: &bag)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    func clear() {
        bag.removeAll()
    }

    // MARK: Dependencies

    @LazyInject var alertViewPresenter: AlertViewPresenterAPI
    @LazyInject var backupRouter: FeatureDashboardUI.BackupRouterAPI
    @LazyInject var coincore: CoincoreAPI
    @LazyInject var customerSupportChatRouter: CustomerSupportChatRouterAPI
    @LazyInject var eligibilityService: EligibilityServiceAPI
    @LazyInject var featureFlagService: FeatureFlagsServiceAPI
    @LazyInject var fiatCurrencyService: FiatCurrencyServiceAPI
    @LazyInject var kycRouter: PlatformUIKit.KYCRouting
    @LazyInject var onboardingRouter: FeatureOnboardingUI.OnboardingRouterAPI
    @LazyInject var receiveCoordinator: ReceiveCoordinator
    @LazyInject var tiersService: KYCTiersServiceAPI
    @LazyInject var transactionsRouter: TransactionsRouterAPI
    @LazyInject var airdropRouter: AirdropRouterAPI
    @Inject var walletConnectService: WalletConnectServiceAPI
    @Inject var walletConnectRouter: WalletConnectRouterAPI

    var pinRouter: PinRouter?
    weak var accountsAndAddressesNavigationController: AccountsAndAddressesNavigationController?

    lazy var bottomSheetPresenter = BottomSheetPresenting()
}

extension RootViewController {

    func subscribe(to viewStore: ViewStore<LoggedIn.State, LoggedIn.Action>) {

        viewStore.publisher
            .reloadAfterMultiAddressResponse
            .filter { $0 }
            .sink(to: My.reload, on: self)
            .store(in: &bag)

        viewStore.publisher
            .reloadAfterSymbolChanged
            .filter { $0 }
            .sink(to: My.reload, on: self)
            .store(in: &bag)

        viewStore.publisher
            .displayWalletAlertContent
            .compactMap { $0 }
            .removeDuplicates()
            .sink(to: My.alert, on: self)
            .store(in: &bag)

        viewStore.publisher
            .displaySendCryptoScreen
            .filter(\.self)
            .sink(to: My.handleSendCrypto, on: self)
            .store(in: &bag)

        viewStore.publisher
            .displayOnboardingFlow
            .filter(\.self)
            .sink(to: My.presentOnboarding, on: self)
            .store(in: &bag)

        viewStore.publisher
            .displayLegacyBuyFlow
            .filter(\.self)
            .sink(to: My.handleBuyCrypto, on: self)
            .store(in: &bag)
    }
}

extension RootViewController {

    func handleFirstFrequentActionButtonInteraction() {
        defaults.hasInteractedWithFrequentActionButton = true
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handle(state: RootViewState, action: RootViewAction) {
        switch action {
        case .frequentAction(let frequentAction):
            switch frequentAction {
            case .swap:
                handleSwapCrypto(account: nil)
            case .send:
                handleSendCrypto()
            case .receive:
                handleReceiveCrypto()
            case .rewards:
                handleRewards()
            case .deposit:
                handleDeposit()
            case .withdraw:
                handleWithdraw()
            case .buy,
                 .sell:
                break // it switches the tab instead of running the flow
            default:
                assertionFailure("Unhandled action \(action)")
            }
        default:
            break
        }
    }
}

extension CacheSuite {

    var hasInteractedWithFrequentActionButton: Bool {
        get { bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
}
