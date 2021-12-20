// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureWithdrawalLocksUI
import Localization
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift
import SwiftUI
import UIKit

// swiftlint:disable:next type_body_length
final class EnterAmountViewController: BaseScreenViewController,
    EnterAmountViewControllable,
    EnterAmountPagePresentable
{

    // MARK: - Auxiliary Views

    private let topAuxiliaryViewContainer = UIView()
    private let bottomAuxiliaryViewContainer = UIView()

    private var topAuxiliaryViewHeightConstraint: NSLayoutConstraint!
    private var bottomAuxiliaryViewHeightConstraint: NSLayoutConstraint!

    private var topAuxiliaryViewController: UIViewController?
    private var bottomAuxiliaryViewController: UIViewController?

    private let topAuxiliaryItemSeparatorView = TitledSeparatorView()
    private let bottomAuxiliaryItemSeparatorView = TitledSeparatorView()

    private lazy var withdrawalLocksHostingController: UIHostingController<WithdrawalLocksView> = {
        let store = Store<WithdrawalLocksState, WithdrawalLocksAction>(
            initialState: .init(),
            reducer: withdrawalLocksReducer,
            environment: WithdrawalLocksEnvironment { [weak self] isVisible in
                self?.withdrawalLocksSeparatorView.isHidden = !isVisible
            }
        )
        return UIHostingController(rootView: WithdrawalLocksView(store: store))
    }()

    private let withdrawalLocksSeparatorView = TitledSeparatorView()

    // MARK: - Main CTA

    private let continueButtonView = ButtonView()
    let continueButtonTapped: Signal<Void>

    private var ctaContainerView = UIView()

    private var errorRecoveryCTAModel: ErrorRecoveryCTAModel
    private let errorRecoveryViewController: UIViewController

    // MARK: - Other Properties

    private let bottomSheetPresenting = BottomSheetPresenting(ignoresBackgroundTouches: true)
    private let amountViewable: AmountViewable
    private let digitPadView = DigitPadView()

    private let closeTriggerred = PublishSubject<Void>()
    private let backTriggered = PublishSubject<Void>()

    // MARK: - Injected

    private let displayBundle: DisplayBundle
    private let devicePresenterType: DevicePresenter.DeviceType
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init(
        displayBundle: DisplayBundle,
        devicePresenterType: DevicePresenter.DeviceType = DevicePresenter.type,
        digitPadViewModel: DigitPadViewModel,
        continueButtonViewModel: ButtonViewModel,
        recoverFromInputError: @escaping () -> Void,
        amountViewProvider: AmountViewable
    ) {
        self.displayBundle = displayBundle
        self.devicePresenterType = devicePresenterType
        amountViewable = amountViewProvider
        continueButtonTapped = continueButtonViewModel.tap

        let errorRecoveryCTAModel = ErrorRecoveryCTAModel(
            buttonTitle: "", // initial state shows no error, and the button is hidden, so this is OK
            action: recoverFromInputError
        )
        self.errorRecoveryCTAModel = errorRecoveryCTAModel
        let errorRecoveryCTA = ErrorRecoveryCTA(model: errorRecoveryCTAModel)
        errorRecoveryViewController = UIHostingController(rootView: errorRecoveryCTA)
        errorRecoveryViewController.view.isHidden = true // initial state shows no error

        super.init(nibName: nil, bundle: nil)

        digitPadView.viewModel = digitPadViewModel
        continueButtonView.viewModel = continueButtonViewModel

        topAuxiliaryItemSeparatorView.viewModel = TitledSeparatorViewModel(separatorColor: .lightBorder)
        bottomAuxiliaryItemSeparatorView.viewModel = TitledSeparatorViewModel(separatorColor: .lightBorder)
        withdrawalLocksSeparatorView.viewModel = TitledSeparatorViewModel(separatorColor: .lightBorder)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        let amountView = amountViewable.view
        view.addSubview(topAuxiliaryViewContainer)
        view.addSubview(topAuxiliaryItemSeparatorView)
        view.addSubview(withdrawalLocksHostingController.view)
        withdrawalLocksHostingController.view.invalidateIntrinsicContentSize()
        if withdrawalLocksHostingController.parent != parent {
            withdrawalLocksHostingController.didMove(toParent: self)
        }
        view.addSubview(withdrawalLocksSeparatorView)
        view.addSubview(amountView)
        view.addSubview(bottomAuxiliaryItemSeparatorView)
        view.addSubview(bottomAuxiliaryViewContainer)
        view.addSubview(digitPadView)

        topAuxiliaryViewContainer.layoutToSuperview(axis: .horizontal)
        topAuxiliaryViewContainer.layoutToSuperview(.top, usesSafeAreaLayoutGuide: true)
        topAuxiliaryViewHeightConstraint = topAuxiliaryViewContainer.layout(
            dimension: .height,
            to: Constant.topSelectionViewHeight(device: devicePresenterType)
        )

        topAuxiliaryItemSeparatorView.layout(edge: .top, to: .bottom, of: topAuxiliaryViewContainer)
        topAuxiliaryItemSeparatorView.layoutToSuperview(axis: .horizontal)
        topAuxiliaryItemSeparatorView.layout(dimension: .height, to: 1)

        withdrawalLocksHostingController.view.layout(edge: .top, to: .bottom, of: topAuxiliaryItemSeparatorView)
        withdrawalLocksHostingController.view.layoutToSuperview(axis: .horizontal)

        withdrawalLocksSeparatorView.layout(edge: .top, to: .bottom, of: withdrawalLocksHostingController.view)
        withdrawalLocksSeparatorView.layoutToSuperview(axis: .horizontal)
        withdrawalLocksSeparatorView.layout(dimension: .height, to: 1)

        amountView.layoutToSuperview(axis: .horizontal)
        amountView.layout(edge: .top, to: .bottom, of: withdrawalLocksSeparatorView)

        bottomAuxiliaryItemSeparatorView.layout(edge: .top, to: .bottom, of: amountView)
        bottomAuxiliaryItemSeparatorView.layoutToSuperview(.leading, priority: .defaultHigh)
        bottomAuxiliaryItemSeparatorView.layoutToSuperview(.trailing)
        bottomAuxiliaryItemSeparatorView.layout(dimension: .height, to: 1)

        bottomAuxiliaryViewHeightConstraint = bottomAuxiliaryViewContainer.layout(
            dimension: .height,
            to: Constant.topSelectionViewHeight(device: devicePresenterType)
        )

        let stackView = UIStackView(arrangedSubviews: [bottomAuxiliaryViewContainer, ctaContainerView])
        stackView.axis = .vertical
        stackView.spacing = 16

        view.addSubview(stackView)
        stackView.layoutToSuperview(.leading, .trailing)
        stackView.layout(
            edge: .top,
            to: .bottom,
            of: bottomAuxiliaryItemSeparatorView,
            priority: .defaultLow
        )
        stackView.layoutToSuperview(axis: .horizontal, offset: 24, priority: .penultimateHigh)

        ctaContainerView.layout(dimension: .height, to: 48)
        ctaContainerView.addSubview(continueButtonView)
        continueButtonView.constraint(edgesTo: ctaContainerView, insets: UIEdgeInsets(horizontal: 24, vertical: .zero))
        embed(errorRecoveryViewController, in: ctaContainerView, insets: UIEdgeInsets(horizontal: 24, vertical: .zero))
        digitPadView.layoutToSuperview(axis: .horizontal, priority: .penultimateHigh)
        digitPadView.layout(edge: .top, to: .bottom, of: stackView, offset: 16)
        digitPadView.layoutToSuperview(.bottom, usesSafeAreaLayoutGuide: true)
        digitPadView.layout(
            dimension: .height,
            to: Constant.digitPadHeight(device: devicePresenterType),
            priority: .penultimateHigh
        )
    }

    func connect(
        state: Driver<EnterAmountPageInteractor.State>
    ) -> Driver<EnterAmountPageInteractor.NavigationEffects> {
        let stateDriver = state
            .distinctUntilChanged()

        stateDriver
            .map(\.topAuxiliaryViewPresenter)
            .drive(weak: self) { (self, presenter) in
                self.topAuxiliaryViewModelStateDidChange(to: presenter)
            }
            .disposed(by: disposeBag)

        stateDriver
            .map(\.bottomAuxiliaryViewPresenter)
            .drive(weak: self) { (self, presenter) in
                self.bottomAuxiliaryViewModelStateDidChange(to: presenter)
            }
            .disposed(by: disposeBag)

        ControlEvent.merge(rx.viewDidLoad.mapToVoid(), rx.viewWillAppear.mapToVoid())
            .asDriver(onErrorJustReturn: ())
            .flatMap { _ in
                state
            }
            .map(\.navigationModel)
            .drive(weak: self) { (self, model) in
                self.setupNavigationBar(model: model)
            }
            .disposed(by: disposeBag)

        let digitInput = digitPadView.viewModel
            .valueObservable
            .asDriverCatchError()

        let deleteInput = digitPadView.viewModel
            .backspaceButtonTapObservable
            .asDriverCatchError()

        let amountViewInputs = [
            digitInput
                .compactMap(\.first)
                .map { AmountPresenterInput.input($0) },
            deleteInput.map { AmountPresenterInput.delete }
        ]

        amountViewable.connect(input: Driver.merge(amountViewInputs))
            .drive()
            .disposed(by: disposeBag)

        stateDriver
            .map(\.canContinue)
            .drive(continueButtonView.viewModel.isEnabledRelay)
            .disposed(by: disposeBag)

        stateDriver
            .map(\.showContinueAction)
            .map { !$0 } // flip the flag because we're modifying the hidden state
            .drive(continueButtonView.viewModel.isHiddenRelay)
            .disposed(by: disposeBag)

        stateDriver
            .map(\.showErrorRecoveryAction)
            .drive(onNext: { [weak errorRecoveryViewController] showError in
                errorRecoveryViewController?.view.isHidden = !showError
            })
            .disposed(by: disposeBag)

        stateDriver
            .map { $0.showContinueAction || $0.showErrorRecoveryAction }
            .drive(onNext: { [ctaContainerView] canShowAnyCTA in
                ctaContainerView.isHidden = !canShowAnyCTA
            })
            .disposed(by: disposeBag)

        stateDriver
            .map(\.errorState)
            .map(\.recoveryWarningHint)
            .drive(onNext: { [errorRecoveryCTAModel] errorTitle in
                errorRecoveryCTAModel.buttonTitle = errorTitle
            })
            .disposed(by: disposeBag)

        stateDriver
            .map(\.showWithdrawalLocks)
            .drive(onNext: { [weak self] showWithdrawalLocks in
                let heightAnchor = self?.withdrawalLocksHostingController.view.heightAnchor
                heightAnchor?.constraint(equalToConstant: 1).isActive = !showWithdrawalLocks
                self?.withdrawalLocksSeparatorView.isHidden = !showWithdrawalLocks
                self?.withdrawalLocksHostingController.view.isHidden = !showWithdrawalLocks
            })
            .disposed(by: disposeBag)

        let backTapped = backTriggered
            .map { EnterAmountPageInteractor.NavigationEffects.back }

        let closeTapped = closeTriggerred
            .map { EnterAmountPageInteractor.NavigationEffects.close }

        return Observable.merge(backTapped, closeTapped)
            .asDriver(onErrorJustReturn: .none)
    }

    // MARK: - Setup

    private func setupNavigationBar(model: ScreenNavigationModel) {
        titleViewStyle = .text(value: displayBundle.title)
        let mayGoBack = model.leadingButton != .none ? (navigationController?.children.count ?? 0) > 1 : false
        set(
            barStyle: model.barStyle,
            leadingButtonStyle: mayGoBack ? .back : .none,
            trailingButtonStyle: model.trailingButton
        )
    }

    private func topAuxiliaryViewModelStateDidChange(to presenter: AuxiliaryViewPresenting?) {
        loadViewIfNeeded()
        remove(child: topAuxiliaryViewController)
        topAuxiliaryViewController = presenter?.makeViewController()

        if let viewController = topAuxiliaryViewController {
            topAuxiliaryViewHeightConstraint.constant = Constant
                .topSelectionViewHeight(device: devicePresenterType)

            embed(viewController, in: topAuxiliaryViewContainer)
            topAuxiliaryItemSeparatorView.alpha = 1
        } else {
            topAuxiliaryViewHeightConstraint.constant = .zero
            topAuxiliaryItemSeparatorView.alpha = .zero
        }
    }

    private func bottomAuxiliaryViewModelStateDidChange(to presenter: AuxiliaryViewPresenting?) {
        loadViewIfNeeded()
        remove(child: bottomAuxiliaryViewController)
        bottomAuxiliaryViewController = presenter?.makeViewController()

        if let viewController = bottomAuxiliaryViewController {
            bottomAuxiliaryViewHeightConstraint.constant = Constant
                .bottomSelectionViewHeight(device: devicePresenterType)
            embed(viewController, in: bottomAuxiliaryViewContainer)
            // NOTE: ATM this separator is unused as some auxiliary views already have one.
            bottomAuxiliaryItemSeparatorView.alpha = .zero
        } else {
            bottomAuxiliaryViewHeightConstraint.constant = .zero
            bottomAuxiliaryItemSeparatorView.alpha = .zero
        }
    }

    // MARK: - Navigation

    override func navigationBarLeadingButtonPressed() {
        backTriggered.onNext(())
    }

    override func navigationBarTrailingButtonPressed() {
        closeTriggerred.onNext(())
    }

    // MARK: - Withdrawal Locks

    func presentWithdrawalLocks(amountAvailable: String) {
        let store = Store<WithdrawalLocksInfoState, WithdrawalLocksInfoAction>(
            initialState: WithdrawalLocksInfoState(amountAvailable: amountAvailable),
            reducer: withdrawalLockInfoReducer,
            environment: WithdrawalLocksInfoEnvironment { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        )
        let rootView = WithdrawalLocksInfoView(store: store)
        let viewController = UIHostingController(rootView: rootView)
        viewController.transitioningDelegate = bottomSheetPresenting
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }
}

extension EnterAmountViewController {

    // MARK: - Types

    private enum Constant {
        private enum SuperCompact {
            static let topSelectionViewHeight: CGFloat = 48
            static let bottomAuxiliaryViewOffset: CGFloat = 8
        }

        private enum Compact {
            static let digitPadHeight: CGFloat = 216
        }

        private enum Standard {
            static let digitPadHeight: CGFloat = 260
            static let topSelectionViewHeight: CGFloat = 78
            static let bottomSelectionViewHeight: CGFloat = 78
        }

        static func digitPadHeight(device: DevicePresenter.DeviceType) -> CGFloat {
            switch device {
            case .superCompact, .compact:
                return Compact.digitPadHeight
            case .max, .regular:
                return Standard.digitPadHeight
            }
        }

        static func topSelectionViewHeight(device: DevicePresenter.DeviceType) -> CGFloat {
            switch device {
            case .superCompact:
                return SuperCompact.topSelectionViewHeight
            case .compact, .max, .regular:
                return Standard.topSelectionViewHeight
            }
        }

        static func bottomSelectionViewHeight(device: DevicePresenter.DeviceType) -> CGFloat {
            Standard.bottomSelectionViewHeight
        }
    }
}

extension UIViewController {

    func embed(_ viewController: UIViewController, in subview: UIView, insets: UIEdgeInsets = .zero) {
        addChild(viewController)
        subview.addSubview(viewController.view)
        viewController.view.constraint(edgesTo: subview, insets: insets)
    }

    func remove(child: UIViewController?) {
        guard let child = child, child.parent === self else {
            return
        }
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
}
