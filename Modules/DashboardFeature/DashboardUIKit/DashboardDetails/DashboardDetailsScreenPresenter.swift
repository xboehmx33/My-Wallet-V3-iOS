// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

/// This enum aggregates possible action types that can be done in the dashboard
enum DashboadDetailsAction {
    case routeTo(BlockchainAccount)
}

final class DashboardDetailsScreenPresenter {

    // MARK: - Types

    private typealias AccessilbityId = Accessibility.Identifier.DashboardDetails
    private typealias LocalizedString = LocalizationConstants.DashboardDetails.BalanceCell

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

    /// The dashboard action
    var action: Signal<DashboadDetailsAction> {
        actionRelay.asSignal()
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
        if let walletBalance = self.walletBalance {
            cellTypes.append(.balance(walletBalance.account))
        }
        if let tradingBalance = self.tradingBalance {
            cellTypes.append(.balance(tradingBalance.account))
        }
        if let savingsBalance = self.savingsBalance {
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

    private unowned let router: DashboardRouter
    private let interactor: DashboardDetailsScreenInteractor
    private let actionRelay = PublishRelay<DashboadDetailsAction>()
    private let scrollingEnabledRelay = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(using interactor: DashboardDetailsScreenInteractor,
         with currency: CryptoCurrency,
         fiatCurrency: FiatCurrency,
         router: DashboardRouter) {
        self.router = router
        self.currency = currency
        self.interactor = interactor

        lineChartCellPresenter = AssetLineChartTableViewCellPresenter(
            cryptoCurrency: currency,
            fiatCurrency: fiatCurrency,
            historicalFiatPriceService: interactor.priceServiceAPI
        )

        lineChartCellPresenter.isScrollEnabled
            .drive(scrollingEnabledRelay)
            .disposed(by: disposeBag)

        presenterSelectionRelay
            .compactMap { cellType -> DashboadDetailsAction? in
                switch cellType {
                case .balance(let account):
                    return .routeTo(account)
                case .chart, .priceAlert:
                    return nil
                }
            }
            .bindAndCatch(to: actionRelay)
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
            .flatMap(weak: self) { (self, account) -> Single<BalancePresentationState> in
                account
                    .can(perform: .viewActivity)
                    .map(weak: self) { (self, supported) in
                        switch supported {
                        case false:
                            return .hidden
                        case true:
                            let presenter = self.balanceCellPresenter(account: account)
                            return .visible(presenter, account)
                        }
                    }
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
    }

    private func balanceCellPresenter(account: BlockchainAccount) -> CurrentBalanceCellPresenter {

        let descriptionValue: () -> Observable<String> = { [weak self] in
            guard let self = self else { return .empty() }
            switch account {
            case is CryptoInterestAccount:
                return self.interactor
                    .rate
                    .map { "\(LocalizedString.Description.savingsPrefix) \($0)\(LocalizedString.Description.savingsSuffix)" }
                    .asObservable()
            default:
                return .just(account.currencyType.name)
            }
        }

        return CurrentBalanceCellPresenter(
            interactor: CurrentBalanceCellInteractor(account: account),
            descriptionValue: descriptionValue,
            currency: .crypto(currency),
            titleAccessibilitySuffix: "\(AccessilbityId.CurrentBalanceCell.titleValue)",
            descriptionAccessibilitySuffix: "\(AccessilbityId.CurrentBalanceCell.descriptionValue)",
            pendingAccessibilitySuffix: "\(AccessilbityId.CurrentBalanceCell.pendingValue)",
            descriptors: .default(
                cryptoAccessiblitySuffix: "\(AccessilbityId.CurrentBalanceCell.cryptoValue).\(currency.code)",
                fiatAccessiblitySuffix: "\(AccessilbityId.CurrentBalanceCell.fiatValue).\(currency.code)"
            )
        )
    }
}
