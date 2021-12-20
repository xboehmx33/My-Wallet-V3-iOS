// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import Localization
import PlatformKit
import RxCocoa
import RxDataSources

public protocol LinkedBankViewModelAPI {
    var nameLabelContent: LabelContent { get }
    var limitLabelContent: LabelContent { get }
    var accountLabelContent: LabelContent { get }
    var badgeImageViewModel: BadgeImageViewModel { get }
    /// Determines if the view accepts taps from its custom button or not
    var isCustomButtonEnabled: Bool { get }
    /// PublishRelay for forwarding tap events from the view
    var tapRelay: PublishRelay<Void> { get }
}

public final class BeneficiaryLinkedBankViewModel: LinkedBankViewModelAPI {

    // MARK: - Types

    private typealias AccessibilityId = Accessibility.Identifier.LinkedBankView

    // MARK: - Properties

    public let data: Beneficiary

    public let nameLabelContent: LabelContent
    public let limitLabelContent: LabelContent
    public let accountLabelContent: LabelContent
    public let badgeImageViewModel: BadgeImageViewModel

    public let tapRelay = PublishRelay<Void>()
    public let isCustomButtonEnabled: Bool = false

    // MARK: - Setup

    public init(data: Beneficiary) {
        self.data = data

        badgeImageViewModel = .template(
            image: .local(name: Icon.bank.name, bundle: .componentLibrary),
            templateColor: .secondary,
            backgroundColor: .lightBlueBackground,
            cornerRadius: .round,
            accessibilityIdSuffix: data.identifier
        )
        badgeImageViewModel.marginOffsetRelay.accept(4)

        nameLabelContent = LabelContent(
            text: data.name,
            font: .main(.semibold, 16),
            color: .titleText,
            accessibility: .id("\(AccessibilityId.name)\(data.identifier)")
        )

        var limitText = ""
        if let limit = data.limit {
            limitText = "\(limit.toDisplayString(includeSymbol: true)) \(LocalizationConstants.Settings.Bank.dailyLimit)"
        }

        limitLabelContent = LabelContent(
            text: limitText,
            font: .main(.medium, 14),
            color: .descriptionText,
            accessibility: .id("\(AccessibilityId.limits)\(data.identifier)")
        )

        accountLabelContent = LabelContent(
            text: data.account,
            font: .main(.semibold, 16),
            color: .titleText,
            accessibility: .id("\(AccessibilityId.account)\(data.identifier)")
        )
    }
}

extension BeneficiaryLinkedBankViewModel: IdentifiableType {
    public var identity: String {
        "\(data.identifier)-\(data.name)-\(data.account)"
    }
}

extension BeneficiaryLinkedBankViewModel: Equatable {
    public static func == (lhs: BeneficiaryLinkedBankViewModel, rhs: BeneficiaryLinkedBankViewModel) -> Bool {
        lhs.data == rhs.data
    }
}

extension Accessibility.Identifier {
    fileprivate enum LinkedBankView {
        private static let prefix = "LinkedBankView."
        static let image = "\(prefix)image"
        static let name = "\(prefix)name."
        static let limits = "\(prefix)limits."
        static let account = "\(prefix)account."
    }
}
