// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import PlatformKit
import RxDataSources
import ToolKit

public struct AccountPickerCellItem: IdentifiableType {

    // MARK: - Properties

    public enum Presenter {
        case emptyState(LabelContent)
        case withdrawalLocks
        case button(ButtonViewModel)
        case linkedBankAccount(LinkedBankAccountCellPresenter)
        case paymentMethodAccount(PaymentMethodCellPresenter)
        case accountGroup(AccountGroupBalanceCellPresenter)
        case singleAccount(AccountCurrentBalanceCellPresenter)
    }

    enum Interactor {
        case emptyState
        case withdrawalLocks
        case button(ButtonViewModel)
        case linkedBankAccount(LinkedBankAccount)
        case paymentMethodAccount(PaymentMethodAccount)
        case accountGroup(AccountGroup, AccountGroupBalanceCellInteractor)
        case singleAccount(SingleAccount, AssetBalanceViewInteracting)
    }

    public var identity: AnyHashable {
        switch presenter {
        case .emptyState:
            return "emptyState"
        case .button:
            return "button"
        case .withdrawalLocks:
            return "withdrawalLocks"
        case .accountGroup,
             .linkedBankAccount,
             .paymentMethodAccount,
             .singleAccount:
            if let identifier = account?.identifier {
                return identifier
            }
            unimplemented()
        }
    }

    public let account: BlockchainAccount?
    public let presenter: Presenter

    public var isButton: Bool {
        if case .button = presenter {
            return true
        } else {
            return false
        }
    }

    init(interactor: Interactor, assetAction: AssetAction) {
        switch interactor {
        case .emptyState:
            account = nil
            let labelContent = LabelContent(
                text: LocalizationConstants.Dashboard.Prices.noResults,
                font: .main(.medium, 16),
                color: .darkTitleText,
                alignment: .center
            )
            presenter = .emptyState(labelContent)
        case .withdrawalLocks:
            account = nil
            presenter = .withdrawalLocks
        case .button(let viewModel):
            account = nil
            presenter = .button(viewModel)

        case .linkedBankAccount(let account):
            self.account = account
            presenter = .linkedBankAccount(
                .init(account: account, action: assetAction)
            )

        case .paymentMethodAccount(let account):
            self.account = account
            presenter = .paymentMethodAccount(
                .init(account: account, action: assetAction)
            )

        case .singleAccount(let account, let interactor):
            self.account = account
            presenter = .singleAccount(
                AccountCurrentBalanceCellPresenter(
                    account: account,
                    assetAction: assetAction,
                    interactor: interactor
                )
            )

        case .accountGroup(let account, let interactor):
            self.account = account
            presenter = .accountGroup(
                AccountGroupBalanceCellPresenter(
                    account: account,
                    interactor: interactor
                )
            )
        }
    }
}
