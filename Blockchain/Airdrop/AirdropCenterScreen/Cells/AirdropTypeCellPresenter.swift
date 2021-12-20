// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import PlatformUIKit
import ToolKit

struct AirdropTypeCellPresenter {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.Airdrop.CenterScreen.Cell
    private typealias AccessibilityId = Accessibility.Identifier.AirdropCenterScreen.Cell

    // MARK: - Properties

    let title: LabelContent
    let description: LabelContent
    let image: ImageViewContent

    var campaignIdentifier: String {
        interactor.campaignIdentifier
    }

    // MARK: - Injected

    private let interactor: AirdropTypeCellInteractor

    // MARK: - Setup

    init(interactor: AirdropTypeCellInteractor) {
        self.interactor = interactor
        image = ImageViewContent(
            imageResource: interactor.cryptoCurrency.logoResource,
            accessibility: .id(AccessibilityId.image)
        )
        let title: String
        if let value = interactor.fiatValue {
            title = "\(value.toDisplayString(includeSymbol: true)) \(LocalizedString.fiatMiddle) \(interactor.cryptoCurrency.displayCode)"
        } else {
            // If the fiat value is missing, then it was not returned by the backend.
            // make sure to display something.
            title = interactor.cryptoCurrency.displayCode
        }

        self.title = .init(
            text: title,
            font: .main(.medium, 16),
            color: .titleText,
            accessibility: .id("\(AccessibilityId.title)\(interactor.campaignIdentifier)")
        )
        let description: String
        if let dropDate = interactor.dropDate {
            let date = DateFormatter.nominalReadable.string(from: dropDate)
            let prefix: String
            if interactor.isAvailable {
                prefix = LocalizedString.availableDescriptionPrefix
            } else {
                prefix = LocalizedString.endedDescriptionPrefix
            }
            description = "\(prefix) \(date)"
        } else { // Empty description
            description = ""
        }
        self.description = .init(
            text: description,
            font: .main(.medium, 12),
            color: .descriptionText,
            accessibility: .id("\(AccessibilityId.title)\(interactor.campaignIdentifier)")
        )
    }
}
