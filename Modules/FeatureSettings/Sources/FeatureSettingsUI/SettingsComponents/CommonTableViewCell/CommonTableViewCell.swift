// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformUIKit

struct CommonCellViewModel {
    let title: String
    let icon: UIImage?
    let showsIndicator: Bool
    let overrideTintColor: UIColor?
    let accessibilityID: String
    let titleAccessibilityID: String

    init(
        title: String,
        icon: UIImage? = nil,
        showsIndicator: Bool = true,
        overrideTintColor: UIColor? = nil,
        accessibilityID: String,
        titleAccessibilityID: String
    ) {
        self.title = title
        self.icon = icon
        self.showsIndicator = showsIndicator
        self.overrideTintColor = overrideTintColor
        self.accessibilityID = accessibilityID
        self.titleAccessibilityID = titleAccessibilityID
    }
}

final class CommonTableViewCell: UITableViewCell {

    // MARK: - Model

    typealias ViewModel = CommonCellViewModel

    var viewModel: ViewModel! {
        didSet {
            titleLabel.text = viewModel.title
            titleLabel.accessibility = .id(viewModel.titleAccessibilityID)
            accessibility = .id(viewModel.accessibilityID)
            if let icon = viewModel.icon {
                iconImageView.image = viewModel.overrideTintColor != nil
                    ? icon.withRenderingMode(.alwaysTemplate)
                    : icon
                iconImageView.sizeToFit()
                if iconImageView.superview == nil {
                    hStack.insertArrangedSubview(iconImageView, at: 0)
                }
            } else {
                iconImageView.removeFromSuperview()
            }
            accessoryType = viewModel.showsIndicator ? .disclosureIndicator : .none
            iconImageView.tintColor = viewModel.overrideTintColor
            titleLabel.textColor = viewModel.overrideTintColor ?? .titleText
        }
    }

    // MARK: - Private IBOutlets

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var hStack: UIStackView!
}
