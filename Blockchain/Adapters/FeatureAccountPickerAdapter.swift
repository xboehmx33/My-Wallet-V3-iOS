// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAccountPickerUI
import FeatureWithdrawalLocksUI
import Foundation
import PlatformUIKit
import RxCocoa
import RxSwift
import SwiftUI
import ToolKit
import UIComponentsKit

/// Helper for `Either<Loading, Either<Left, Right>>`
typealias LoadableEitherViewController<
    Left: ViewControllerProvider,
    Right: ViewControllerProvider
> = EitherViewController<
    UIHostingController<LoadingStateView>,
    Either<Left, Right>
>

/// Async switching controller to pick the appropriate controller based on the feature flag
class LoadableAccountPickerControllable: LoadableEitherViewController<
    FeatureAccountPickerControllableAdapter,
    AccountPickerViewController
>,
    AccountPickerViewControllable
{
    var shouldOverrideNavigationEffects: Bool = false

    private var state: Driver<AccountPickerPresenter.State>?
    private let effects = BehaviorRelay<AccountPickerInteractor.Effects>(value: .none)
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @LazyInject private var featureFlagService: FeatureFlagsServiceAPI

    typealias Child = Either<
        UIHostingController<LoadingStateView>,
        Either<
            FeatureAccountPickerControllableAdapter,
            AccountPickerViewController
        >
    >

    init() {
        super.init(child: .left(UIHostingController(rootView: LoadingStateView(title: ""))))

        featureFlagService.isEnabled(.remote(.swiftUIAccountPicker))
            .sink { [weak self] isEnabled in
                guard let self = self else { return }

                switch isEnabled {
                case true:
                    self.child = .right(.left(FeatureAccountPickerControllableAdapter()))
                case false:
                    self.child = .right(.right(AccountPickerViewController()))
                }
            }
            .store(in: &cancellables)
    }

    func connect(state: Driver<AccountPickerPresenter.State>) -> Driver<AccountPickerInteractor.Effects> {
        self.state = state

        defer {
            connectChildIfPossible()
        }

        return effects.asDriverCatchError()
    }

    func connectChildIfPossible() {
        guard let controllable = child.viewController as? AccountPickerViewControllable,
              let state = state
        else {
            return
        }

        controllable
            .connect(state: state)
            .drive(effects)
            .disposed(by: disposeBag)
    }

    override func updateChild(from oldValue: Child) {
        super.updateChild(from: oldValue)

        disposeBag = DisposeBag()
    }

    override func updateChild(to newValue: Child) {
        if let controllable = newValue.viewController as? AccountPickerViewControllable {
            controllable.shouldOverrideNavigationEffects = shouldOverrideNavigationEffects
        }

        disposeBag = DisposeBag()

        connectChildIfPossible()

        super.updateChild(to: newValue)
    }
}

class FeatureAccountPickerControllableAdapter: BaseScreenViewController {

    // MARK: - Private Properties

    fileprivate var disposeBag = DisposeBag()
    var shouldOverrideNavigationEffects: Bool = false

    fileprivate let modelSelectedRelay = PublishRelay<AccountPickerCellItem>()
    fileprivate let backButtonRelay = PublishRelay<Void>()
    fileprivate let closeButtonRelay = PublishRelay<Void>()
    private let searchRelay = PublishRelay<String?>()
    fileprivate let sections = PassthroughSubject<[AccountPickerRow], Never>()
    fileprivate let header = PassthroughSubject<HeaderStyle, Error>()

    fileprivate lazy var environment = AccountPickerEnvironment(
        rowSelected: { [unowned self] (identifier: AnyHashable) -> Void in
            let viewModel = self.model(for: identifier)
            if let viewModel = viewModel {
                self.modelSelectedRelay.accept(viewModel)
            }
        },
        backButtonTapped: { [unowned self] in self.backButtonRelay.accept(()) },
        closeButtonTapped: { [unowned self] in self.closeButtonRelay.accept(()) },
        search: { [unowned self] searchText in self.searchRelay.accept(searchText) },
        sections: { [unowned self] in self.sections.eraseToAnyPublisher() },
        updateSingleAccounts: { [unowned self] ids in
            let presenters = Dictionary(uniqueKeysWithValues: ids.map { ($0, self.presenter(for: $0)) })
            let publishers = presenters
                .compactMap { id, presenter
                    -> AnyPublisher<(AnyHashable, AccountPickerRow.SingleAccount.Balances), Error>? in

                    guard case .singleAccount(let item) = presenter else {
                        return nil
                    }

                    return item.assetBalanceViewPresenter.state
                        .asPublisher()
                        .map { value -> (AnyHashable, AccountPickerRow.SingleAccount.Balances) in
                            switch value {
                            case .loading:
                                return (
                                    id,
                                    .init(
                                        fiatBalance: .loading,
                                        cryptoBalance: .loading
                                    )
                                )
                            case .loaded(let balance):
                                return (
                                    id,
                                    .init(
                                        fiatBalance: .loaded(next: balance.primaryBalance.text),
                                        cryptoBalance: .loaded(next: balance.secondaryBalance.text)
                                    )
                                )
                            }
                        }
                        .eraseToAnyPublisher()
                }

            return Publishers.MergeMany(publishers)
                .collect(publishers.count)
                .map { Dictionary($0) { _, right in right } } // Don't care which value we take, just no dupes
                .eraseToAnyPublisher()
        },
        updateAccountGroups: { [unowned self] ids in
            let presenters = Dictionary(uniqueKeysWithValues: ids.map { ($0, self.presenter(for: $0)) })
            let publishers = presenters
                .compactMap { id, presenter
                    -> AnyPublisher<(AnyHashable, AccountPickerRow.AccountGroup.Balances), Error>? in

                    guard case .accountGroup(let item) = presenter else {
                        return nil
                    }

                    return item.walletBalanceViewPresenter.state
                        .asPublisher()
                        .map { value -> (AnyHashable, AccountPickerRow.AccountGroup.Balances) in
                            switch value {
                            case .loading:
                                return (
                                    id,
                                    .init(
                                        fiatBalance: .loading,
                                        currencyCode: .loading
                                    )
                                )
                            case .loaded(let balance):
                                return (
                                    id,
                                    .init(
                                        fiatBalance: .loaded(next: balance.fiatBalance.text),
                                        currencyCode: .loaded(next: balance.currencyCode.text)
                                    )
                                )
                            }
                        }
                        .eraseToAnyPublisher()
                }

            return Publishers.MergeMany(publishers)
                .collect(publishers.count)
                .map { Dictionary($0) { _, right in right } } // Don't care which value we take, just no dupes.
                .eraseToAnyPublisher()
        },
        header: { [header] in header.eraseToAnyPublisher() }
    )

    fileprivate var models: [AccountPickerSectionViewModel] = []

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
        let child = UIHostingController(
            rootView: AccountPickerView(
                environment: environment,
                badgeView: { [unowned self] identity in
                    self.badgeView(for: identity)
                },
                iconView: { [unowned self] identity in
                    self.iconView(for: identity)
                },
                multiBadgeView: { [unowned self] identity in
                    self.multiBadgeView(for: identity)
                },
                withdrawalLocksView: { [unowned self] in
                    self.withdrawalLocksView()
                }
            )
        )
        addChild(child)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        children.forEach { child in
            view.addSubview(child.view)
            child.view.fillSuperview(usesSafeAreaLayoutGuide: true)
            child.didMove(toParent: self)
        }
    }

    // MARK: - Methods

    override func navigationBarLeadingButtonPressed() {
        guard shouldOverrideNavigationEffects else {
            super.navigationBarLeadingButtonPressed()
            return
        }
        switch leadingButtonStyle {
        case .close:
            closeButtonRelay.accept(())
        case .back:
            backButtonRelay.accept(())
        default:
            super.navigationBarLeadingButtonPressed()
        }
    }

    override func navigationBarTrailingButtonPressed() {
        guard shouldOverrideNavigationEffects else {
            super.navigationBarTrailingButtonPressed()
            return
        }
        switch trailingButtonStyle {
        case .close:
            closeButtonRelay.accept(())
        default:
            super.navigationBarLeadingButtonPressed()
        }
    }

    // MARK: - View Functions

    func model(for identity: AnyHashable) -> AccountPickerCellItem? {
        models.lazy
            .flatMap(\.items)
            .first(where: { $0.identity == identity })
    }

    func presenter(for identity: AnyHashable) -> AccountPickerCellItem.Presenter? {
        model(for: identity)?
            .presenter
    }

    @ViewBuilder func badgeView(for identity: AnyHashable) -> some View {
        switch presenter(for: identity) {
        case .singleAccount(let presenter):
            BadgeImageViewRepresentable(viewModel: presenter.badgeRelay.value, size: 32)
        case .accountGroup(let presenter):
            BadgeImageViewRepresentable(viewModel: presenter.badgeImageViewModel, size: 32)
        default:
            EmptyView()
        }
    }

    @ViewBuilder func iconView(for identity: AnyHashable) -> some View {
        switch presenter(for: identity) {
        case .singleAccount(let presenter):
            BadgeImageViewRepresentable(
                viewModel: presenter.iconImageViewContentRelay.value,
                size: 16
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder func multiBadgeView(for identity: AnyHashable) -> some View {
        switch presenter(for: identity) {
        case .linkedBankAccount(let presenter):
            MultiBadgeViewRepresentable(viewModel: presenter.multiBadgeViewModel)
        case .singleAccount(let presenter):
            MultiBadgeViewRepresentable(viewModel: .just(presenter.multiBadgeViewModel))
        default:
            EmptyView()
        }
    }

    @ViewBuilder func withdrawalLocksView() -> some View {
        let store = Store<WithdrawalLocksState, WithdrawalLocksAction>(
            initialState: .init(),
            reducer: withdrawalLocksReducer,
            environment: WithdrawalLocksEnvironment { _ in }
        )
        WithdrawalLocksView(store: store)
    }
}

extension FeatureAccountPickerControllableAdapter: AccountPickerViewControllable {

    // swiftlint:disable:next function_body_length
    func connect(state: Driver<AccountPickerPresenter.State>) -> Driver<AccountPickerInteractor.Effects> {
        disposeBag = DisposeBag()

        let stateWait: Driver<AccountPickerPresenter.State> =
            rx.viewDidLoad
                .asDriver()
                .flatMap { _ in
                    state
                }

        stateWait
            .map(\.navigationModel)
            .drive(weak: self) { (self, model) in
                if let model = model {
                    self.navigationController?.setNavigationBarHidden(false, animated: false)
                    self.titleViewStyle = model.titleViewStyle
                    self.set(
                        barStyle: model.barStyle,
                        leadingButtonStyle: model.leadingButton,
                        trailingButtonStyle: model.trailingButton
                    )
                } else {
                    self.navigationController?.setNavigationBarHidden(true, animated: false)
                }
            }
            .disposed(by: disposeBag)

        stateWait.map(\.headerModel)
            .drive(weak: self) { (self, headerType) in
                let header: HeaderStyle
                switch headerType {
                case .default(let model):
                    header = .normal(
                        title: model.title,
                        subtitle: model.subtitle,
                        image: model.imageContent.imageResource?.image,
                        tableTitle: model.tableTitle,
                        searchable: model.searchable
                    )
                case .simple(let model):
                    header = .simple(subtitle: model.subtitle)
                case .none:
                    header = .none
                }
                self.header.send(header)
            }
            .disposed(by: disposeBag)

        stateWait.map(\.sections)
            .drive(weak: self) { (self, sectionModels) in
                self.models = sectionModels
                let sections = sectionModels
                    .flatMap(\.items)
                    .map { (item: AccountPickerCellItem) -> AccountPickerRow in
                        switch item.presenter {
                        case .emptyState(let labelContent):
                            return .label(
                                .init(
                                    id: item.identity,
                                    text: labelContent.text
                                )
                            )
                        case .button(let viewModel):
                            return .button(
                                .init(
                                    id: item.identity,
                                    text: viewModel.textRelay.value
                                )
                            )

                        case .linkedBankAccount(let presenter):
                            return .linkedBankAccount(
                                .init(
                                    id: item.identity,
                                    title: presenter.account.label,
                                    description: LocalizationConstants.accountEndingIn
                                        + " \(presenter.account.accountNumber)"
                                )
                            )

                        case .paymentMethodAccount(let presenter):
                            return .paymentMethodAccount(
                                .init(
                                    id: item.identity,
                                    title: presenter.account.label,
                                    description: presenter
                                        .account
                                        .paymentMethodType
                                        .balance
                                        .displayString,
                                    badgeView: presenter.account.logoResource.image,
                                    badgeBackground: Color(presenter.account.logoBackgroundColor)
                                )
                            )

                        case .accountGroup(let presenter):
                            return .accountGroup(
                                .init(
                                    id: item.identity,
                                    title: presenter.account.label,
                                    description: LocalizationConstants.Dashboard.Portfolio.totalBalance
                                )
                            )

                        case .singleAccount(let presenter):
                            return .singleAccount(
                                .init(
                                    id: item.identity,
                                    title: presenter.account.currencyType.name,
                                    description: presenter.account.label
                                )
                            )
                        case .withdrawalLocks:
                            return .withdrawalLocks
                        }
                    }
                self.sections.send(sections)
            }
            .disposed(by: disposeBag)

        let modelSelected = modelSelectedRelay
            .compactMap(\.account)
            .map { AccountPickerInteractor.Effects.select($0) }
            .asDriver(onErrorJustReturn: .none)

        let buttonSelected = modelSelectedRelay
            .filter(\.isButton)
            .map { _ in AccountPickerInteractor.Effects.button }
            .asDriver(onErrorJustReturn: .none)

        let backButtonEffect = backButtonRelay
            .map { AccountPickerInteractor.Effects.back }
            .asDriverCatchError()

        let closeButtonEffect = closeButtonRelay
            .map { AccountPickerInteractor.Effects.closed }
            .asDriverCatchError()

        let searchEffect = searchRelay
            .map { AccountPickerInteractor.Effects.filter($0) }
            .asDriverCatchError()

        return .merge(modelSelected, buttonSelected, backButtonEffect, closeButtonEffect, searchEffect)
    }
}
