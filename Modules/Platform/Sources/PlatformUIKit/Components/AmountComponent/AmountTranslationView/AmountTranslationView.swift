// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit
import UIComponentsKit
import UIKit

public final class AmountTranslationView: UIView, AmountViewable {

    public var view: UIView {
        self
    }

    // MARK: - Types

    private struct AmountLabelConstraints {
        var top: [NSLayoutConstraint]
        var bottom: [NSLayoutConstraint]

        init(top: [NSLayoutConstraint], bottom: [NSLayoutConstraint]) {
            self.top = top
            self.bottom = bottom
        }

        func activate() {
            top.forEach { $0.priority = .penultimateHigh }
            bottom.forEach { $0.priority = .penultimateLow }
        }

        func deactivate() {
            top.forEach { $0.priority = .penultimateLow }
            bottom.forEach { $0.priority = .penultimateHigh }
        }
    }

    // MARK: - Properties

    private let fiatAmountLabelView = AmountLabelView()
    private let cryptoAmountLabelView = AmountLabelView()
    private let auxiliaryButton = ButtonView()
    private let swapButton: UIButton = {
        var swapButton = UIButton()
        swapButton.layer.borderWidth = 1
        swapButton.layer.cornerRadius = 8
        swapButton.layer.borderColor = UIColor.mediumBorder.cgColor
        swapButton.setImage(UIImage(named: "vertical-swap-icon", in: .platformUIKit, with: nil), for: .normal)
        return swapButton
    }()

    private let presenter: AmountTranslationPresenter

    private let disposeBag = DisposeBag()

    private var fiatLabelConstraints: AmountLabelConstraints!
    private var cryptoLabelConstraints: AmountLabelConstraints!

    // MARK: - Init

    @available(*, unavailable)
    public required init?(coder: NSCoder) { unimplemented() }

    public init(presenter: AmountTranslationPresenter) {
        self.presenter = presenter
        super.init(frame: UIScreen.main.bounds)

        fiatAmountLabelView.presenter = presenter.fiatPresenter.presenter
        cryptoAmountLabelView.presenter = presenter.cryptoPresenter.presenter

        func setupConstraints(for amountLabelView: UIView, isActive: Bool) -> AmountLabelConstraints {
            amountLabelView.layoutToSuperview(.centerX)
            amountLabelView.layout(dimension: .height, to: 48)

            let topPriority: UILayoutPriority = isActive ? .penultimateHigh : .penultimateLow
            let topLeadingConstraint = amountLabelView.layoutToSuperview(
                .leading,
                relation: .greaterThanOrEqual,
                offset: 24,
                priority: topPriority
            )!
            let topTrailingConstraint = amountLabelView.layoutToSuperview(
                .trailing,
                relation: .lessThanOrEqual,
                offset: -24,
                priority: topPriority
            )!
            let topVerticalConstraint = amountLabelView.layout(
                edge: .bottom,
                to: .centerY,
                of: self,
                priority: topPriority
            )!

            let top = [
                topLeadingConstraint,
                topTrailingConstraint,
                topVerticalConstraint
            ]

            let bottomPriority: UILayoutPriority = isActive ? .penultimateLow : .penultimateHigh
            let bottomLeadingConstraint = amountLabelView.layoutToSuperview(
                .leading,
                relation: .greaterThanOrEqual,
                offset: 24,
                priority: topPriority
            )!
            let bottomTrailingConstraint = amountLabelView.layout(
                edge: .trailing,
                to: .leading,
                of: swapButton,
                relation: .lessThanOrEqual,
                offset: -16,
                priority: topPriority
            )!
            let bottomVerticalConstraint = amountLabelView.layout(
                edge: .top,
                to: .centerY,
                of: self,
                priority: bottomPriority
            )!

            let bottom = [
                bottomLeadingConstraint,
                bottomTrailingConstraint,
                bottomVerticalConstraint
            ]

            return AmountLabelConstraints(top: top, bottom: bottom)
        }

        addSubview(fiatAmountLabelView)
        addSubview(cryptoAmountLabelView)
        addSubview(auxiliaryButton)
        addSubview(swapButton)

        fiatLabelConstraints = setupConstraints(for: fiatAmountLabelView, isActive: true)
        cryptoLabelConstraints = setupConstraints(for: cryptoAmountLabelView, isActive: false)

        cryptoLabelConstraints.bottom.append(
            swapButton.layout(
                to: .centerY,
                of: cryptoAmountLabelView,
                priority: .penultimateHigh
            )!
        )
        fiatLabelConstraints.bottom.append(
            swapButton.layout(
                to: .centerY,
                of: fiatAmountLabelView,
                priority: .penultimateLow
            )!
        )

        cryptoLabelConstraints.bottom.append(
            auxiliaryButton.layout(
                to: .centerY,
                of: cryptoAmountLabelView,
                priority: .penultimateHigh
            )!
        )
        fiatLabelConstraints.bottom.append(
            auxiliaryButton.layout(
                to: .centerY,
                of: fiatAmountLabelView,
                priority: .penultimateLow
            )!
        )

        auxiliaryButton.layoutToSuperview(.centerX)
        auxiliaryButton.layout(
            edge: .trailing,
            to: .leading,
            of: swapButton,
            relation: .lessThanOrEqual,
            offset: 0
        )

        swapButton.layout(size: .init(edge: 40))
        swapButton.layout(to: .trailing, of: self, offset: -16)

        presenter.swapButtonVisibility
            .drive(swapButton.rx.visibility)
            .disposed(by: disposeBag)

        swapButton.rx.tap
            .bindAndCatch(to: presenter.swapButtonTapRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .map { input -> Bool in
                input == .fiat
            }
            .drive(fiatAmountLabelView.presenter.focusRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .map { input -> Bool in
                input == .crypto
            }
            .drive(cryptoAmountLabelView.presenter.focusRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .drive(
                onNext: { [weak self] input in
                    self?.didChangeActiveInput(to: input)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Public Methods

    public func connect(input: Driver<AmountPresenterInput>) -> Driver<AmountPresenterState> {
        Driver.combineLatest(
            presenter.connect(input: input),
            presenter.activeAmountInput,
            presenter.auxiliaryButtonEnabled
        )
        .map { (state: $0.0, activeAmountInput: $0.1, auxiliaryEnabled: $0.2) }
        .map { [weak self] value in
            guard let self = self else { return .empty }
            return self.performEffect(
                state: value.state,
                activeAmountInput: value.activeAmountInput,
                auxiliaryButtonEnabled: value.auxiliaryEnabled
            )
        }
    }

    // MARK: - Private Methods

    private func performEffect(
        state: AmountPresenterState,
        activeAmountInput: ActiveAmountInput,
        auxiliaryButtonEnabled: Bool
    ) -> AmountPresenterState {
        let limitButtonVisibility: Visibility
        let textColor: UIColor
        switch state {
        case .warning(let viewModel):
            auxiliaryButton.viewModel = viewModel
            limitButtonVisibility = .visible
            textColor = auxiliaryButtonEnabled ? .validInput : .invalidInput
        case .showSecondaryAmountLabel:
            auxiliaryButton.viewModel = nil
            limitButtonVisibility = .hidden
            textColor = .validInput
        case .empty:
            auxiliaryButton.viewModel = nil
            limitButtonVisibility = .hidden
            textColor = .validInput
        case .showLimitButton:
            unimplemented()
        }

        let fiatVisibility: Visibility
        let cryptoVisibility: Visibility
        switch activeAmountInput {
        case .fiat:
            fiatVisibility = .visible
            cryptoVisibility = auxiliaryButtonEnabled ? limitButtonVisibility.inverted : .visible
        case .crypto:
            cryptoVisibility = .visible
            fiatVisibility = auxiliaryButtonEnabled ? limitButtonVisibility.inverted : .visible
        }
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: {
                self.auxiliaryButton.alpha = auxiliaryButtonEnabled ? limitButtonVisibility.defaultAlpha : 0
                self.auxiliaryButton.isHidden = !auxiliaryButtonEnabled || limitButtonVisibility.isHidden
                self.fiatAmountLabelView.alpha = fiatVisibility.defaultAlpha
                self.cryptoAmountLabelView.alpha = cryptoVisibility.defaultAlpha
                self.fiatAmountLabelView.textColor = textColor
                self.cryptoAmountLabelView.textColor = textColor
            },
            completion: nil
        )
        return state
    }

    private func didChangeActiveInput(to newInput: ActiveAmountInput) {
        layoutIfNeeded()
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: {
                switch newInput {
                case .fiat:
                    self.fiatLabelConstraints.activate()
                    self.cryptoLabelConstraints.deactivate()
                case .crypto:
                    self.cryptoLabelConstraints.activate()
                    self.fiatLabelConstraints.deactivate()
                }
                self.layoutIfNeeded()
            },
            completion: nil
        )
    }
}
