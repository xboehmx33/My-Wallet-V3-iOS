// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import FeatureOpenBankingDomain
import Session
import SwiftUI
import ToolKit
import UIComponentsKit

// swiftlint:disable type_name

public struct BankState: Equatable {

    public struct UI: Equatable {

        public enum Action: Hashable {
            case retry(label: String, action: BankAction)
            case next
            case ok
            case cancel
        }

        public let info: InfoView.Model
        public internal(set) var action: [Action]?
    }

    public internal(set) var ui: UI?
    public internal(set) var data: OpenBanking.Data

    var account: OpenBanking.BankAccount { data.account }

    var bankName: String {
        switch data.action {
        case .link(let institution):
            return institution.fullName
        case .deposit, .confirm:
            return account.details?.bankName ?? Localization.Bank.yourBank
        }
    }
}

public enum BankAction: Hashable, FailureAction {
    case retry
    case request
    case launchAuthorisation(URL)
    case waitingForConsent
    case finalise(OpenBanking.Output)
    case cancel
    case dismiss
    case finished
    case failure(OpenBanking.Error)
}

public let bankReducer = Reducer<BankState, BankAction, OpenBankingEnvironment> { state, action, environment in

    enum ID {
        struct Request: Hashable {}
        struct LaunchBank: Hashable {}
        struct ConsentError: Hashable {}
    }

    switch action {
    case .retry:
        return .merge(
            .cancel(id: ID.Request()),
            .cancel(id: ID.LaunchBank()),
            Effect(value: .request)
        )
    case .request:
        state.ui = .communicating(to: state.bankName)
        return .merge(
            .fireAndForget {
                environment.openBanking.reset()
            },
            environment.openBanking.start(state.data)
                .compactMap { state in
                    switch state {
                    case .waitingForConsent:
                        return .waitingForConsent
                    case .success(let output):
                        return .finalise(output)
                    case .failure(let error):
                        return BankAction.failure(error)
                    }
                }
                .receive(on: environment.scheduler)
                .eraseToEffect()
                .cancellable(id: ID.Request())
        )

    case .waitingForConsent:
        return environment.openBanking.authorisationURLPublisher
            .map(BankAction.launchAuthorisation)
            .receive(on: environment.scheduler)
            .eraseToEffect()
            .cancellable(id: ID.LaunchBank())

    case .launchAuthorisation(let url):
        state.ui = .waiting(for: state.bankName)
        return .merge(
            .fireAndForget { environment.openURL.open(url) },
            .cancel(id: ID.LaunchBank())
        )

    case .finalise(let output):
        switch output {
        case .linked:
            state.ui = .linked(institution: state.bankName)
        case .deposited(let payment):
            state.ui = .deposit(success: payment, in: environment)
        case .confirmed(let order) where order.state == .finished:
            state.ui = .buy(finished: order, in: environment)
        case .confirmed(let order):
            state.ui = .buy(pending: order, in: environment)
        }
        return .merge(
            .cancel(id: ID.ConsentError()),
            .cancel(id: ID.Request())
        )

    case .dismiss:
        return .fireAndForget(environment.dismiss)

    case .finished, .cancel:
        return .merge(
            .cancel(id: ID.ConsentError()),
            .cancel(id: ID.Request())
        )

    case .failure(let error):
        state.ui = .error(error)
        return .cancel(id: ID.ConsentError())
    }
}

public struct BankView: View {

    private let store: Store<BankState, BankAction>

    public init(store: Store<BankState, BankAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            if let ui = viewStore.ui {
                ActionableView(
                    ui.info,
                    buttons: buttons(from: ui.action, in: viewStore),
                    in: .openBanking
                )
                .trailingNavigationButton(.close) {
                    viewStore.send(.dismiss)
                }
            } else {
                ProgressView(value: 0.25)
                    .progressViewStyle(IndeterminateProgressStyle())
                    .onAppear {
                        viewStore.send(.request)
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .whiteNavigationBarStyle()
    }

    private typealias ButtonState = ActionableView<
        TupleView<(Spacer, InfoView, Spacer)>
    >.ButtonState

    private func buttons(
        from actions: [BankState.UI.Action]?,
        in viewStore: ViewStore<BankState, BankAction>
    ) -> [ButtonState] {
        guard let actions = actions else { return [] }
        return actions
            .enumerated()
            .map { i, action in
                let style: ButtonState.Style = i == 0 ? .primary : .secondary
                switch action {
                case .ok:
                    return .init(
                        title: Localization.Bank.Action.ok,
                        action: { viewStore.send(.finished) },
                        style: style
                    )
                case .next:
                    return .init(
                        title: Localization.Bank.Action.next,
                        action: { viewStore.send(.finished) },
                        style: style
                    )
                case .retry(let label, let action):
                    return .init(
                        title: label,
                        action: { viewStore.send(action) },
                        style: style
                    )
                case .cancel:
                    return .init(
                        title: Localization.Bank.Action.cancel,
                        action: { viewStore.send(.cancel) },
                        style: style
                    )
                }
            }
    }
}

#if DEBUG
struct BankView_Previews: PreviewProvider {

    static var previews: some View {
        BankView(
            store: .init(
                initialState: BankState(
                    ui: .linked(institution: "Monzo"),
                    data: .init(account: .mock, action: .link(institution: .mock))
                ),
                reducer: bankReducer,
                environment: .mock
            )
        )
    }
}
#endif
