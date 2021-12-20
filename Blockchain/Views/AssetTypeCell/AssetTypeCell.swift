// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit
import ToolKit

@objc protocol AssetTypeCellDelegate {
    func didTapChevronButton()
}

/// Cell shown for selecting an asset type from the drop-down menu (AssetSelectorView).
@objc class AssetTypeCell: UITableViewCell {

    @objc var legacyAssetType: LegacyAssetType = .bitcoin

    @objc weak var delegate: AssetTypeCellDelegate?

    @IBOutlet private var assetImageView: UIImageView!
    @IBOutlet private var label: UILabel!

    // Used to open and close the AssetSelectorView.
    @IBOutlet private var chevronButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        chevronButton.accessibility = .id(AccessibilityIdentifiers.AssetSelection.toggleButton)
        contentView.backgroundColor = UIColor.NavigationBar.LightContent.background
    }

    @objc func configure(with assetType: LegacyAssetType, showChevronButton: Bool) {
        legacyAssetType = assetType
        let cryptoCurrency = assetType.cryptoCurrency
        assetImageView.image = cryptoCurrency.whiteImageSmall
        label.text = cryptoCurrency.name
        chevronButton.isHidden = !showChevronButton
        accessibilityIdentifier = "\(AccessibilityIdentifiers.AssetSelection.assetPrefix)\(cryptoCurrency.displayCode)"
    }

    @IBAction private func chevronButtonTapped(_ sender: UIButton) {
        delegate?.didTapChevronButton()
    }
}

@objc extension AssetTypeCell {
    func pointChevronButton(_ direction: Direction) {
        switch direction {
        case .up:
            UIView.animate(withDuration: Constants.Animation.duration) {
                self.chevronButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            }
        case .down:
            UIView.animate(withDuration: Constants.Animation.duration) {
                self.chevronButton.transform = CGAffineTransform(rotationAngle: 0)
            }
        }
    }
}

// AssetTypeCell is a legacy component that is only used with BTC/BCH, so these are the only coins with added images.
extension CryptoCurrency {
    private var whiteImageName: String? {
        switch self {
        case .coin(.bitcoin):
            return "white_btc_small"
        case .coin(.bitcoinCash):
            return "white_bch_small"
        default:
            return nil
        }
    }

    fileprivate var whiteImageSmall: UIImage? {
        guard let whiteImageName = whiteImageName else {
            return nil
        }
        return UIImage(named: whiteImageName)
    }
}
