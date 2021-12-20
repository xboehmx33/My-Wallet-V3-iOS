// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import SwiftUI

public enum AccountPickerRow: Equatable, Identifiable {
    case label(Label)
    case button(Button)
    case linkedBankAccount(LinkedBankAccount)
    case paymentMethodAccount(PaymentMethod)
    case accountGroup(AccountGroup)
    case singleAccount(SingleAccount)
    case withdrawalLocks

    public var id: AnyHashable {
        switch self {
        case .label(let model):
            return model.id
        case .button(let model):
            return model.id
        case .linkedBankAccount(let model):
            return model.id
        case .paymentMethodAccount(let model):
            return model.id
        case .accountGroup(let model):
            return model.id
        case .singleAccount(let model):
            return model.id
        case .withdrawalLocks:
            return "withdrawal-locks-id"
        }
    }

    var isAccountGroup: Bool {
        switch self {
        case .accountGroup:
            return true
        default:
            return false
        }
    }

    var isSingleAccount: Bool {
        switch self {
        case .singleAccount:
            return true
        default:
            return false
        }
    }
}
