// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitectureExtensions
import DIKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

public final class PortfolioScreenPresenter {

    // MARK: - Types

    private typealias CurrencyBalance = (currency: CryptoCurrency, hasBalance: Bool)

    struct Model {
        let totalBalancePresenter: TotalBalanceViewPresenter
        var announcementCardViewModel: AnnouncementCardViewModel?
        var fiatBalanceCollectionViewPresenter: CurrencyViewPresenter?
        var cryptoCurrencies: [CryptoCurrency: LoadingState<Bool>]

        func cellArrangement(
            interactor: (CryptoCurrency) -> HistoricalBalanceCellInteractor?
        ) -> [PortfolioCellType] {
            let emptyCryptoCurrencies = cryptoCurrencies
                .filter { $0.value.value == true }
                .map(\.key)
                .isEmpty

            switch (emptyCryptoCurrencies, cryptoCurrencies.contains(where: \.value.isLoading)) {
            case (false, _):
                return loadedArrangement(interactor: interactor)
            case (true, false):
                return emptyStateArrangement(interactor: interactor)
            case (true, true):
                return loadingArrangement
            }
        }

        private func emptyStateArrangement(
            interactor: (CryptoCurrency) -> HistoricalBalanceCellInteractor?
        ) -> [PortfolioCellType] {
            guard fiatBalanceCollectionViewPresenter == nil else {
                return loadedArrangement(interactor: interactor)
            }
            return addingAnnouncement(items: [.emptyState])
        }

        private func loadedArrangement(
            interactor: (CryptoCurrency) -> HistoricalBalanceCellInteractor?
        ) -> [PortfolioCellType] {
            var items: [PortfolioCellType] = [
                .totalBalance(totalBalancePresenter),
                .withdrawalLock
            ]
            if let fiatBalanceCollectionViewPresenter = fiatBalanceCollectionViewPresenter {
                items.append(.fiatCustodialBalances(fiatBalanceCollectionViewPresenter))
            }

            cryptoCurrencies
                .filter { $0.value.value == true }
                .map(\.key)
                .sorted()
                .compactMap { cryptoCurrency in
                    guard let interactor = interactor(cryptoCurrency) else {
                        return nil
                    }
                    return HistoricalBalanceCellPresenter(interactor: interactor)
                }
                .map(PortfolioCellType.crypto)
                .forEach { items.append($0) }
            return addingAnnouncement(items: items)
        }

        private var loadingArrangement: [PortfolioCellType] {
            var items: [PortfolioCellType] = [
                .totalBalance(totalBalancePresenter)
            ]
            if let fiatBalanceCollectionViewPresenter = fiatBalanceCollectionViewPresenter {
                items.append(.fiatCustodialBalances(fiatBalanceCollectionViewPresenter))
            }
            Array(1...3)
                .map(PortfolioCellType.cryptoSkeleton)
                .forEach { items.append($0) }
            return addingAnnouncement(items: items)
        }

        private func addingAnnouncement(items: [PortfolioCellType]) -> [PortfolioCellType] {
            var items = items
            if let announcementCardViewModel = announcementCardViewModel {
                switch announcementCardViewModel.priority {
                case .high: // Prepend
                    items.insert(.announcement(announcementCardViewModel), at: 0)
                case .low: // Append
                    items.append(.announcement(announcementCardViewModel))
                }
            }
            return items
        }
    }

    // MARK: - Internal Properties

    /// Should be triggered when user pulls-to-refresh.
    let refreshRelay = BehaviorRelay<Void>(value: ())
    let fiatBalancePresenter: DashboardFiatBalancesPresenter
    var model: Model
    private(set) lazy var router: PortfolioRouter = .init()
    var sections: Observable<[PortfolioViewModel]> {
        sectionsRelay.asObservable()
    }

    var isEmptyState: Observable<Bool> {
        sections
            .compactMap { portfolioViewModels in portfolioViewModels.first }
            .map(\.items)
            .map { items in
                let hasCrypto = items.filter { cellType in
                    switch cellType {
                    case .crypto:
                        return true
                    default:
                        return false
                    }
                }
                return hasCrypto.isEmpty
            }
    }

    var screenNavigationModel: ScreenNavigationModel {
        ScreenNavigationModel(
            leadingButton: .drawer,
            trailingButton: .qrCode,
            titleViewStyle: .text(value: LocalizationConstants.DashboardScreen.title),
            barStyle: .lightContent()
        )
    }

    // MARK: - Private Properties

    private let accountFetcher: BlockchainAccountFetching
    private let announcementPresenter: AnnouncementPresenting
    private let disposeBag = DisposeBag()
    private let drawerRouter: DrawerRouting
    private let interactor: PortfolioScreenInteractor
    private let reloadRelay: PublishRelay<Void> = .init()
    private let sectionsRelay: BehaviorRelay<[PortfolioViewModel]> = .init(value: [])
    private let coincore: CoincoreAPI

    private var cryptoCurrencies: Observable<CurrencyBalance> {
        let cryptoStreams: [Observable<CurrencyBalance>] = coincore.cryptoAssets
            .map { asset -> Observable<CurrencyBalance> in
                let currency = asset.asset
                return asset.accountGroup(filter: .all)
                    .asObservable()
                    .asSingle()
                    .flatMap { group -> Single<Bool> in
                        group.balance.map(\.isPositive)
                    }
                    .map { hasBalance -> CurrencyBalance in
                        (currency, hasBalance)
                    }
                    .asObservable()
                    .catchErrorJustReturn((currency, false))
            }
        return Observable
            .merge(cryptoStreams)
            .compactMap { $0 }
    }

    // MARK: - Init

    public init(
        interactor: PortfolioScreenInteractor = PortfolioScreenInteractor(),
        accountFetcher: BlockchainAccountFetching = resolve(),
        drawerRouter: DrawerRouting = resolve(),
        announcementPresenter: AnnouncementPresenting = resolve(),
        coincore: CoincoreAPI = resolve(),
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve()
    ) {
        self.accountFetcher = accountFetcher
        self.announcementPresenter = announcementPresenter
        self.coincore = coincore
        self.drawerRouter = drawerRouter
        self.interactor = interactor
        fiatBalancePresenter = DashboardFiatBalancesPresenter(
            interactor: interactor.fiatBalancesInteractor
        )
        let totalBalancePresenter = TotalBalanceViewPresenter(
            coincore: coincore,
            fiatCurrencyService: fiatCurrencyService
        )
        let enabledCryptoCurrencies = interactor.enabledCryptoCurrencies
            .reduce(into: [CryptoCurrency: LoadingState<Bool>]()) { result, cryptoCurrency in
                result[cryptoCurrency] = .loading
            }
        model = Model(
            totalBalancePresenter: totalBalancePresenter,
            cryptoCurrencies: enabledCryptoCurrencies
        )
    }

    // MARK: - Navigation

    /// Should be invoked upon tapping navigation bar leading button
    func navigationBarLeadingButtonPressed() {
        drawerRouter.toggleSideMenu()
    }

    // MARK: - Setup

    /// Should be called once the view is loaded
    func setup() {
        // Bind announcements.
        announcementPresenter.announcement
            .do(onNext: { [weak self] action in
                switch action {
                case .hide:
                    self?.model.announcementCardViewModel = nil
                case .show(let viewModel):
                    self?.model.announcementCardViewModel = viewModel
                case .none:
                    break
                }
            })
            .asObservable()
            .mapToVoid()
            .bindAndCatch(to: reloadRelay)
            .disposed(by: disposeBag)

        // Bind fiat balances.
        fiatBalancePresenter.action
            .do(onNext: { [weak self] action in
                switch action {
                case .hide:
                    self?.model.fiatBalanceCollectionViewPresenter = nil
                case .show(let presenter):
                    self?.model.fiatBalanceCollectionViewPresenter = presenter
                }
            })
            .asObservable()
            .mapToVoid()
            .bindAndCatch(to: reloadRelay)
            .disposed(by: disposeBag)

        // Bind fiat balances details.
        fiatBalancePresenter
            .tap
            .asObservable()
            .compactMap(\.viewModel)
            .flatMapLatest { [accountFetcher] currencyType in
                accountFetcher
                    .account(for: currencyType, accountType: .nonCustodial)
                    .asObservable()
            }
            .bind { [router] account in
                router.showWalletActionScreen(for: account)
            }
            .disposed(by: disposeBag)

        reloadRelay
            .startWith(())
            .throttle(.milliseconds(250), scheduler: MainScheduler.asyncInstance)
            .map(weak: self) { (self, _) in
                self.model.cellArrangement { cryptoCurrency in
                    self.interactor.historicalBalanceCellInteractor(for: cryptoCurrency)
                }
            }
            .map(PortfolioViewModel.init)
            .map { [$0] }
            .bind(to: sectionsRelay)
            .disposed(by: disposeBag)

        refreshRelay
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .bind { [weak self] _ in
                self?.didRefresh()
            }
            .disposed(by: disposeBag)

        refreshRelay
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .flatMapLatest(weak: self) { (self, _) in
                self.cryptoCurrencies
            }
            .do(
                onNext: { [weak self] data in
                    self?.model.cryptoCurrencies[data.currency] = .loaded(next: data.hasBalance)
                }
            )
            .mapToVoid()
            .bindAndCatch(to: reloadRelay)
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods

    private func didRefresh() {
        interactor.refresh()
        announcementPresenter.refresh()
        fiatBalancePresenter.refresh()
        model.totalBalancePresenter.refresh()
    }
}
