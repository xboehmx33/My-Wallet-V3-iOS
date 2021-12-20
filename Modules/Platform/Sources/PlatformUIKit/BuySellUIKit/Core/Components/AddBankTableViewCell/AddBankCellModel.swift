// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit
import RxDataSources

final class AddBankCellModel {

    private typealias AccessibilityId = Accessibility.Identifier.AddBankView
    private typealias LocalizedString = LocalizationConstants.Settings.Bank

    let titleLabelContent: LabelContent
    let badgeImageViewModel: BadgeImageViewModel

    let fiatCurrency: FiatCurrency

    init(fiatCurrency: FiatCurrency) {
        self.fiatCurrency = fiatCurrency

        badgeImageViewModel = .template(
            image: .local(name: "icon-bank", bundle: .platformUIKit),
            templateColor: .secondary,
            backgroundColor: .clear,
            cornerRadius: .none,
            accessibilityIdSuffix: AccessibilityId.image
        )
        badgeImageViewModel.marginOffsetRelay.accept(0)

        titleLabelContent = LabelContent(
            text: "\(LocalizedString.addPrefix) \(fiatCurrency.displayCode) \(LocalizedString.addSuffix)",
            font: .main(.semibold, 16),
            color: .titleText,
            accessibility: .id("\(AccessibilityId.name)\(fiatCurrency.name)")
        )
    }
}

extension AddBankCellModel: IdentifiableType {
    public var identity: String {
        fiatCurrency.name
    }
}

extension AddBankCellModel: Equatable {
    public static func == (lhs: AddBankCellModel, rhs: AddBankCellModel) -> Bool {
        lhs.fiatCurrency == rhs.fiatCurrency
    }
}

extension Accessibility.Identifier {
    fileprivate enum AddBankView {
        private static let prefix = "AddBankView."
        static let image = "\(prefix)image"
        static let name = "\(prefix)name."
    }
}
