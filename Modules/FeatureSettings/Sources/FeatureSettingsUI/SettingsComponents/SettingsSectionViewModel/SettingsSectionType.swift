// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import PlatformUIKit
import RxDataSources

enum SettingsSectionType: Int, Equatable {
    case profile = 1
    case preferences = 2
    case connect = 3
    case security = 4
    case banks = 5
    case cards = 6
    case help = 7

    enum CellType: Equatable, IdentifiableType {

        var identity: AnyHashable {
            switch self {
            case .badge(let type, _):
                return type.rawValue
            case .banks(let type):
                return type.identity
            case .cards(let type):
                return type.identity
            case .clipboard(let type):
                return type.rawValue
            case .common(let type):
                return type.rawValue
            case .switch(let type, _):
                return type.rawValue
            }
        }

        static func == (lhs: SettingsSectionType.CellType, rhs: SettingsSectionType.CellType) -> Bool {
            switch (lhs, rhs) {
            case (.badge(let left, _), .badge(let right, _)):
                return left == right
            case (.switch(let left, _), .switch(let right, _)):
                return left == right
            case (.clipboard(let left), .clipboard(let right)):
                return left == right
            case (.cards(let left), .cards(let right)):
                return left == right
            case (.common(let left), .common(let right)):
                return left == right
            case (.banks(let left), .banks(let right)):
                return left == right
            default:
                return false
            }
        }

        case badge(BadgeCellType, BadgeCellPresenting)
        case `switch`(SwitchCellType, SwitchCellPresenting)
        case clipboard(ClipboardCellType)
        case cards(LinkedPaymentMethodCellType<AddPaymentMethodCellPresenter, LinkedCardCellPresenter>)
        case banks(LinkedPaymentMethodCellType<AddPaymentMethodCellPresenter, BeneficiaryLinkedBankViewModel>)
        case common(CommonCellType)

        enum BadgeCellType: String {
            case limits
            case emailVerification
            case mobileVerification
            case currencyPreference
            case pitConnection
            case recoveryPhrase
        }

        enum SwitchCellType: String {
            case cloudBackup
            case sms2FA
            case emailNotifications
            case balanceSyncing
            case bioAuthentication
        }

        enum ClipboardCellType: String {
            case walletID
        }

        /// Any payment method can get under this category
        enum LinkedPaymentMethodCellType<
            AddNewCellPresenter: IdentifiableType,
            LinkedCellPresenter: Equatable & IdentifiableType
        >: Equatable, IdentifiableType {
            var identity: AnyHashable {
                switch self {
                case .skeleton(let index):
                    return "skeleton.\(index)"
                case .add(let presenter):
                    return presenter.identity
                case .linked(let presenter):
                    return presenter.identity
                }
            }

            case skeleton(Int)
            case linked(LinkedCellPresenter)
            case add(AddNewCellPresenter)

            static func == (
                lhs: SettingsSectionType.CellType.LinkedPaymentMethodCellType<AddNewCellPresenter, LinkedCellPresenter>,
                rhs: SettingsSectionType.CellType.LinkedPaymentMethodCellType<AddNewCellPresenter, LinkedCellPresenter>
            ) -> Bool {
                switch (lhs, rhs) {
                case (.skeleton(let left), .skeleton(let right)):
                    return left == right
                case (.linked(let left), .linked(let right)):
                    return left == right
                case (.add(let lhsPresenter), .add(let rhsPresenter)):
                    return lhsPresenter.identity == rhsPresenter.identity
                default:
                    return false
                }
            }
        }

        enum CommonCellType: String {
            case loginToWebWallet
            case webLogin
            case changePassword
            case changePIN
            case rateUs
            case termsOfService
            case privacyPolicy
            case cookiesPolicy
            case logout
            case addresses
            case contactSupport
            case airdrops
        }
    }
}

extension SettingsSectionType {
    static let `default`: [SettingsSectionType] = [
        .profile,
        .preferences,
        .security,
        .help
    ]
}
