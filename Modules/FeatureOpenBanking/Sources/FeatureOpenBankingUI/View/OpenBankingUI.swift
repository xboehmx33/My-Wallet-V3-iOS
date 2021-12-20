// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
@_exported import FeatureOpenBankingDomain
import SwiftUI

public enum OpenBankingState: Equatable {
    case institutionList(InstitutionListState)
    case approve(ApproveState)
}

extension OpenBankingState {

    public static func linkBankAccount(_ bankAccount: OpenBanking.BankAccount? = nil) -> Self {
        if let bankAccount = bankAccount {
            return .institutionList(.init(result: .success(bankAccount)))
        } else {
            return .institutionList(.init())
        }
    }

    public static func deposit(
        amountMinor: String,
        product: String,
        from bankAccount: OpenBanking.BankAccount
    ) -> Self {
        .approve(
            .init(
                bank: .init(
                    data: .init(
                        account: bankAccount,
                        action: .deposit(
                            amountMinor: amountMinor,
                            product: product
                        )
                    )
                )
            )
        )
    }

    public static func confirm(
        order: OpenBanking.Order,
        from bankAccount: OpenBanking.BankAccount
    ) -> Self {
        .approve(
            .init(
                bank: .init(
                    data: .init(
                        account: bankAccount,
                        action: .confirm(
                            order: order
                        )
                    )
                )
            )
        )
    }
}

public enum OpenBankingAction: Equatable {
    case institutionList(InstitutionListAction)
    case approve(ApproveAction)
}

public let openBankingReducer = Reducer<OpenBankingState, OpenBankingAction, OpenBankingEnvironment>
    .combine(
        institutionListReducer
            .pullback(
                state: /OpenBankingState.institutionList,
                action: /OpenBankingAction.institutionList,
                environment: \.environment
            ),
        approveReducer
            .pullback(
                state: /OpenBankingState.approve,
                action: /OpenBankingAction.approve,
                environment: \.environment
            ),
        .init { _, action, environment in
            switch action {
            case .approve(.bank(.failure(let error))),
                 .institutionList(.approve(.bank(.failure(let error)))):
                environment.eventPublisher.send(.failure(error))
                return .none
            case .institutionList(.approve(.bank(.finished))), .approve(.bank(.finished)):
                environment.eventPublisher.send(.success(()))
                return .none
            case .institutionList(.approve(.deny)), .approve(.deny), .approve(.bank(.cancel)):
                return .fireAndForget(environment.cancel)
            case .approve:
                return .none
            case .institutionList:
                return .none
            }
        }
    )

public struct OpenBankingView: View {

    let store: Store<OpenBankingState, OpenBankingAction>

    public init(store: Store<OpenBankingState, OpenBankingAction>) {
        self.store = store
    }

    public var body: some View {
        SwitchStore(store) {
            CaseLet(
                state: /OpenBankingState.institutionList,
                action: OpenBankingAction.institutionList,
                then: InstitutionList.init(store:)
            )
            CaseLet(
                state: /OpenBankingState.approve,
                action: OpenBankingAction.approve,
                then: ApproveView.init(store:)
            )
        }
    }
}
