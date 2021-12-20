// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import Foundation
import enum Localization.LocalizationConstants
import SwiftUI
import UIComponentsKit

typealias Localization = LocalizationConstants.Transaction

public struct TooManyPendingOrdersView: View {

    var count: Int

    var viewActivityAction: (() -> Void)?
    var okAction: (() -> Void)?

    public var body: some View {
        ActionableView(
            .init(
                media: .image(named: "icon_cart"),
                overlay: .init(progress: true),
                title: Localization.Error.pendingTransactionLimit,
                subtitle: String.localizedStringWithFormat(Localization.Error.maximumPendingOrderLimitReached, "\(count)")
            ),
            buttons: [
                .init(
                    title: Localization.viewActivity,
                    action: {
                        viewActivityAction?()
                    },
                    style: .secondary
                ),
                .init(
                    title: Localization.ok,
                    action: {
                        okAction?()
                    },
                    style: .primary
                )
            ],
            in: .platformUIKit
        )
    }
}

public struct TooManyPendingOrdersErrorView: View {

    var okAction: (() -> Void)?

    public var body: some View {
        ActionableView(
            .init(
                media: .image(named: "triangle-error-icon"),
                title: Localization.Error.unknownErrorShort,
                subtitle: Localization.Error.unknownError
            ),
            buttons: [
                .init(
                    title: Localization.ok,
                    action: {
                        okAction?()
                    },
                    style: .primary
                )
            ],
            in: .platformUIKit
        )
    }
}
