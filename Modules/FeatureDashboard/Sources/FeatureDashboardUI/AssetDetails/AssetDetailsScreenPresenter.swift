// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

/// This enum aggregates possible action types that can be done in the dashboard
enum AssetDetailsAction {
    case routeTo(BlockchainAccount)
}

final class AssetDetailsScreenPresenter {

    // MARK: - Types

    private typealias AccessibilityId = Accessibility.Identifier.AssetDetails
    private typealias LocalizedString = LocalizationConstants.Dashboard.BalanceCell.Description

    enum CellType: Hashable {
        case balance(BlockchainAccount)
        case priceAlert
        case chart

        private var id: AnyHashable {
            switch self {
            case .balance(let account):
                return account.identifier
            case .priceAlert:
                return "priceAlert"
            case .chart:
                return "chart"
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum BalancePresentationState {
        case visible(CurrentBalanceCellPresenter, BlockchainAccount)
        case hidden

        /// Returns presenter and account if `self` is visible.
        var visible: (presenter: CurrentBalanceCellPresenter, account: BlockchainAccount)? {
            switch self {
            case .visible(let presenter, let account):
                return (presenter, account)
            case .hidden:
                return nil
            }
        }
    }

    enum PresentationAction {
        case show(BlockchainAccount)
    }

    // MARK: - Navigation Properties

    var trailingButton: Screen.Style.TrailingButton {
        .none
    }

    var leadingButton: Screen.Style.LeadingButton {
        .close
    }

    var titleView: Screen.Style.TitleView {
        .text(value: currency.name)
    }

    var barStyle: Screen.Style.Bar {
        .lightContent()
    }

    // MARK: - Rx

    var isScrollEnabled: Driver<Bool> {
        scrollingEnabledRelay.asDriver()
    }

    var tradingAccount = BehaviorRelay<CryptoCurrency?>(value: nil)

    var presentationAction: Signal<PresentationAction> {
        presentationActionRelay.asSignal()
    }

    // MARK: - Exposed Properties

    var walletBalance: (presenter: CurrentBalanceCellPresenter, account: BlockchainAccount)? {
        walletBalanceStateRelay.value.visible
    }

    var tradingBalance: (presenter: CurrentBalanceCellPresenter, account: BlockchainAccount)? {
        tradingBalanceStateRelay.value.visible
    }

    var savingsBalance: (presenter: CurrentBalanceCellPresenter, account: BlockchainAccount)? {
        savingsBalanceStateRelay.value.visible
    }

    /// Returns the total count of cells
    var cellCount: Int {
        cellArrangement.count
    }

    /// Returns the ordered cell types
    var cellArrangement: [CellType] {
        var cellTypes: [CellType] = []
        cellTypes.append(.priceAlert)
        cellTypes.append(.chart)
        if let walletBalance = walletBalance {
            cellTypes.append(.balance(walletBalance.account))
        }
        if let tradingBalance = tradingBalance {
            cellTypes.append(.balance(tradingBalance.account))
        }
        if let savingsBalance = savingsBalance {
            cellTypes.append(.balance(savingsBalance.account))
        }
        return cellTypes
    }

    func index(for account: BlockchainAccount) -> Int? {
        cellArrangement.firstIndex(of: .balance(account))
    }

    // MARK: - Public Properties (Presenters)

    let lineChartCellPresenter: AssetLineChartTableViewCellPresenter

    let currency: CryptoCurrency

    /// Selection relay for a single presenter
    let presenterSelectionRelay = PublishRelay<CellType>()

    // MARK: - Private Properties

    private let presentationActionRelay = PublishRelay<PresentationAction>()
    private let walletBalanceStateRelay = BehaviorRelay<BalancePresentationState>(value: .hidden)
    private let tradingBalanceStateRelay = BehaviorRelay<BalancePresentationState>(value: .hidden)
    private let savingsBalanceStateRelay = BehaviorRelay<BalancePresentationState>(value: .hidden)

    private let accountsRouter: AccountsRouting
    private let interactor: AssetDetailsScreenInteractor
    private let scrollingEnabledRelay = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        accountsRouter: AccountsRouting,
        using interactor: AssetDetailsScreenInteractor,
        with currency: CryptoCurrency
    ) {
        self.accountsRouter = accountsRouter
        self.currency = currency
        self.interactor = interactor

        lineChartCellPresenter = AssetLineChartTableViewCellPresenter(
            cryptoCurrency: currency,
            fiatCurrencyService: interactor.fiatCurrencyService,
            historicalFiatPriceService: interactor.historicalFiatPriceService
        )

        lineChartCellPresenter.isScrollEnabled
            .drive(scrollingEnabledRelay)
            .disposed(by: disposeBag)

        presenterSelectionRelay
            .compactMap { cellType -> BlockchainAccount? in
                switch cellType {
                case .balance(let account):
                    return account
                case .chart,
                     .priceAlert:
                    return nil
                }
            }
            .bind { [accountsRouter] blockchainAccount in
                accountsRouter.route(to: blockchainAccount)
            }
            .disposed(by: disposeBag)
    }

    /// Should be called on `viewDidLoad`
    func setup() {
        setupWalletBalancePresenter()
        setupTradingBalancePresenter()
        setupSavingsBalancePresenter()

        interactor.refresh()
    }

    private func setupWalletBalancePresenter() {
        interactor.nonCustodialAccount
            .map(weak: self) { (self, account) -> BalancePresentationState in
                let presenter = self.balanceCellPresenter(account: account)
                return .visible(presenter, account)
            }
            .asObservable()
            .catchErrorJustReturn(.hidden)
            .bindAndCatch(to: walletBalanceStateRelay)
            .disposed(by: disposeBag)

        walletBalanceStateRelay
            .compactMap { $0.visible?.account }
            .map { .show($0) }
            .bindAndCatch(to: presentationActionRelay)
            .disposed(by: disposeBag)
    }

    private func setupSavingsBalancePresenter() {
        interactor.interestAccountIfFunded
            .map(weak: self) { (self, account) -> BalancePresentationState in
                switch account {
                case .none:
                    return .hidden
                case .some(let account):
                    let presenter = self.balanceCellPresenter(account: account)
                    return .visible(presenter, account)
                }
            }
            .asObservable()
            .catchErrorJustReturn(.hidden)
            .bindAndCatch(to: savingsBalanceStateRelay)
            .disposed(by: disposeBag)

        savingsBalanceStateRelay
            .compactMap { $0.visible?.account }
            .map { .show($0) }
            .bindAndCatch(to: presentationActionRelay)
            .disposed(by: disposeBag)
    }

    private func setupTradingBalancePresenter() {
        interactor.tradingAccount
            .map(weak: self) { (self, account) -> BalancePresentationState in
                let presenter = self.balanceCellPresenter(account: account)
                return .visible(presenter, account)
            }
            .asObservable()
            .catchErrorJustReturn(.hidden)
            .bindAndCatch(to: tradingBalanceStateRelay)
            .disposed(by: disposeBag)

        tradingBalanceStateRelay
            .compactMap { $0.visible?.account }
            .map { .show($0) }
            .bindAndCatch(to: presentationActionRelay)
            .disposed(by: disposeBag)

        tradingBalanceStateRelay
            .compactMap { $0.visible?.account }
            .map { [weak self] _ in self?.currency }
            .bindAndCatch(to: tradingAccount)
            .disposed(by: disposeBag)
    }

    private func balanceCellPresenter(account: BlockchainAccount) -> CurrentBalanceCellPresenter {
        let descriptionValue: () -> Observable<String> = { [weak self] in
            guard let self = self else { return .empty() }
            switch account {
            case is CryptoInterestAccount:
                return self.interactor
                    .rate
                    .map { "\(LocalizedString.savingsPrefix) \($0)\(LocalizedString.savingsSuffix)" }
                    .asObservable()
            default:
                return .just(account.currencyType.name)
            }
        }

        return CurrentBalanceCellPresenter(
            interactor: CurrentBalanceCellInteractor(account: account),
            descriptionValue: descriptionValue,
            currency: .crypto(currency),
            viewAccessibilitySuffix: "\(AccessibilityId.CurrentBalanceCell.view)",
            titleAccessibilitySuffix: "\(AccessibilityId.CurrentBalanceCell.titleValue)",
            descriptionAccessibilitySuffix: "\(AccessibilityId.CurrentBalanceCell.descriptionValue)",
            pendingAccessibilitySuffix: "\(AccessibilityId.CurrentBalanceCell.pendingValue)",
            descriptors: .default(
                cryptoAccessiblitySuffix: "\(AccessibilityId.CurrentBalanceCell.cryptoValue).\(currency.code)",
                fiatAccessiblitySuffix: "\(AccessibilityId.CurrentBalanceCell.fiatValue).\(currency.code)"
            )
        )
    }
}
