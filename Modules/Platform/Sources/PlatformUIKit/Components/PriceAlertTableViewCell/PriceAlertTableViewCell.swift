// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit

/// NOTE: There is currently a `UIButton` in `PriceAlertTableViewCell`.
/// In a future release this will be for toggling price alerts. Currently
/// the button is not visible.
public final class PriceAlertTableViewCell: UITableViewCell {

    private typealias LocalizationId = LocalizationConstants.Dashboard.AssetDetails

    public var currency: CryptoCurrency! {
        didSet {
            let text = "\(LocalizationId.current) \(currency.displayCode) \(LocalizationId.price)"
            currentPriceLabel.content = LabelContent(
                text: text,
                font: .main(.medium, 16.0),
                color: .descriptionText,
                alignment: .center,
                accessibility: .none
            )
        }
    }

    @IBOutlet private var currentPriceLabel: UILabel!
}
