// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import ComposableArchitecture
import ComposableNavigation
import DIKit
import FeatureWithdrawalLocksDomain
import Localization
import SwiftUI

public struct WithdrawalLocksInfoState: Hashable, NavigationState {
    public var route: RouteIntent<WithdrawalLocksInfoRoute>?
    public var withdrawalLocks: WithdrawalLocks?
    public let amountAvailable: String

    public init(amountAvailable: String) {
        self.amountAvailable = amountAvailable
    }
}

public enum WithdrawalLocksInfoAction: Hashable, NavigationAction {
    case loadWithdrawalLocks
    case dismiss
    case present(withdrawalLocks: WithdrawalLocks?)
    case route(RouteIntent<WithdrawalLocksInfoRoute>?)
}

public enum WithdrawalLocksInfoRoute: NavigationRoute {
    case details(withdrawalLocks: WithdrawalLocks)

    public func destination(in store: Store<WithdrawalLocksInfoState, WithdrawalLocksInfoAction>) -> some View {
        switch self {
        case .details(let withdrawalLocks):
            return WithdrawalLocksDetailsView(withdrawalLocks: withdrawalLocks)
        }
    }
}

public struct WithdrawalLocksInfoEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let withdrawalLockService: WithdrawalLocksServiceAPI
    let closeAction: (() -> Void)?

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue> = .main,
        withdrawalLockService: WithdrawalLocksServiceAPI = resolve(),
        closeAction: (() -> Void)? = nil
    ) {
        self.mainQueue = mainQueue
        self.withdrawalLockService = withdrawalLockService
        self.closeAction = closeAction
    }
}

public let withdrawalLockInfoReducer = Reducer<
    WithdrawalLocksInfoState,
    WithdrawalLocksInfoAction,
    WithdrawalLocksInfoEnvironment
> { state, action, environment in

    switch action {
    case .loadWithdrawalLocks:
        return .merge(
            environment.withdrawalLockService
                .withdrawLocks
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .map { withdrawalLocks in
                    .present(withdrawalLocks: withdrawalLocks)
                }
        )
    case .present(withdrawalLocks: let withdrawalLocks):
        state.withdrawalLocks = withdrawalLocks
        return .none
    case .route(let routeItent):
        state.route = routeItent
        return .none
    case .dismiss:
        return .fireAndForget {
            environment.closeAction?()
        }
    }
}

public struct WithdrawalLocksInfoView: View {

    let store: Store<WithdrawalLocksInfoState, WithdrawalLocksInfoAction>

    private typealias LocalizationIds = LocalizationConstants.WithdrawalLocks

    public init(store: Store<WithdrawalLocksInfoState, WithdrawalLocksInfoAction>) {
        self.store = store
    }

    @Environment(\.openURL) private var openURL

    public var body: some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .top) {
                HStack {
                    Spacer()
                    IconButton(icon: .closev2.circle()) {
                        viewStore.send(.dismiss)
                    }
                    .frame(width: 24, height: 24)
                }
                .padding([.trailing, .top])

                VStack {
                    Icon.pending
                        .body
                        .frame(height: 60)

                    if let amount = viewStore.withdrawalLocks?.amount {
                        Text(String(format: LocalizationIds.onHoldAmountTitle, amount))
                            .typography(.title3)
                            .padding(.top, 24.pt)
                    } else {
                        Text(" ")
                            .typography(.title3)
                            .padding(.top, 24.pt)
                            .shimmer(enabled: true, width: 100)
                    }

                    Text(LocalizationIds.holdingPeriodDescription)
                        .typography(.paragraph1)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing, .top], 24.pt)

                    Text(LocalizationIds.learnMoreTitle)
                        .typography(.paragraph1)
                        .foregroundColor(.semantic.primary)
                        .onTapGesture {
                            openURL(Constants.withdrawalLocksSupportUrl)
                        }
                        .padding()

                    PrimaryDivider()
                    HStack {
                        Text(LocalizationIds.availableToWithdrawTitle)
                        Spacer()
                        Text(viewStore.amountAvailable)
                    }
                    .foregroundColor(.semantic.body)
                    .typography(.paragraph2)
                    .frame(height: 44)
                    .padding([.leading, .trailing])

                    PrimaryDivider()

                    Spacer()

                    MinimalButton(title: LocalizationIds.seeDetailsButtonTitle) {
                        if let withdrawalLocks = viewStore.state.withdrawalLocks {
                            viewStore.send(.enter(into: .details(withdrawalLocks: withdrawalLocks)))
                        }
                    }
                    .navigationRoute(in: store)
                    .padding()

                    PrimaryButton(title: LocalizationIds.confirmButtonTitle) {
                        viewStore.send(.dismiss)
                    }
                    .padding([.leading, .trailing, .bottom])
                }
                .padding(.top, 70.pt)
            }
            .onAppear {
                viewStore.send(.loadWithdrawalLocks)
            }
            .navigationBarHidden(true)
        }
    }
}

// swiftlint:disable type_name
struct WithdrawalLocksInfoView_PreviewProvider: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WithdrawalLocksInfoView(store:
                .init(
                    initialState: .init(
                        amountAvailable: "$191.12"
                    ),
                    reducer: withdrawalLockInfoReducer,
                    environment: .init(
                        withdrawalLockService: NoOpWithdrawalLocksService()
                    )
                )
            )
        }
    }
}
