// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift

public final class CurrencyLabeledButtonViewModel: LabeledButtonViewModelAPI {

    // MARK: - Types

    private typealias AccessibilityId = Accessibility.Identifier.LabeledButtonCollectionView
    public typealias Element = MoneyValue

    // MARK: - Exposed Properties

    /// Accepts visibility toggle
    public let hiddenRelay = PublishRelay<Bool>()

    /// Accepts taps
    public let tapRelay = PublishRelay<Void>()

    public var elementOnTap: Signal<Element> {
        let amount = amount
        return tapRelay
            .asSignal()
            .map { amount }
    }

    /// Streams the content of the relay
    public var content: Driver<ButtonContent> {
        contentRelay.asDriver()
    }

    /// Determines the background color of the view
    public let backgroundColor: Color

    // MARK: - Private Properties

    private let contentRelay = BehaviorRelay<ButtonContent>(value: .empty)
    private let amount: MoneyValue

    private let disposeBag = DisposeBag()

    // MARK: - Setup

    convenience init(
        amount: MoneyValue,
        format: String = "%@",
        style: LabeledButtonViewStyle = .currency,
        accessibilityId: String
    ) {
        let amountString = amount.toDisplayString(includeSymbol: true)
        let text = String(format: format, amountString)
        let buttonContent = Self.buttonContent(from: style, text: text, amountString: amountString, accessibilityId: accessibilityId)
        self.init(amount: amount, style: style, buttonContent: buttonContent)
    }

    init(
        amount: MoneyValue,
        style: LabeledButtonViewStyle,
        buttonContent: ButtonContent
    ) {
        self.amount = amount
        backgroundColor = style.backgroundColor
        contentRelay.accept(buttonContent)
    }

    private static func buttonContent(
        from style: LabeledButtonViewStyle,
        text: String,
        amountString: String,
        accessibilityId: String
    ) -> ButtonContent {
        ButtonContent(
            text: text,
            font: style.font,
            color: style.textColor,
            backgroundColor: style.backgroundColor,
            border: style.border,
            cornerRadius: style.cornerRadius,
            accessibility: .init(
                id: "\(AccessibilityId.buttonPrefix)\(accessibilityId)",
                label: amountString
            )
        )
    }
}
