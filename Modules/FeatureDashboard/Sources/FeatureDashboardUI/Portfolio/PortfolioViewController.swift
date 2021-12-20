// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import DIKit
import FeatureWithdrawalLocksUI
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxDataSources
import RxRelay
import RxSwift
import ToolKit
import UIComponentsKit

/// A view controller that displays the dashboard
public final class PortfolioViewController: BaseScreenViewController {

    // MARK: - Private Types

    private typealias RxDataSource = RxTableViewSectionedAnimatedDataSource<PortfolioViewModel>

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()
    private let fiatBalanceCellProvider: FiatBalanceCellProviding
    private let presenter: PortfolioScreenPresenter
    private let tableView = UITableView()
    private var buyButton: BuyButtonView

    // MARK: - Setup

    public init(
        fiatBalanceCellProvider: FiatBalanceCellProviding,
        presenter: PortfolioScreenPresenter
    ) {
        self.fiatBalanceCellProvider = fiatBalanceCellProvider
        self.presenter = presenter
        buyButton = BuyButtonView(store: Store<BuyButtonState, BuyButtonAction>(
            initialState: .init(),
            reducer: buyButtonReducer,
            environment: .init()
        ))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        unimplemented()
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupTableView()
        presenter.setup()
        tableView.reloadData()
        presenter.refreshRelay.accept(())

        NotificationCenter.when(.transaction) { [weak self] _ in
            self?.presenter.refreshRelay.accept(())
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = false
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        let model = presenter.screenNavigationModel
        set(
            barStyle: model.barStyle,
            leadingButtonStyle: model.leadingButton,
            trailingButtonStyle: model.trailingButton
        )
        titleViewStyle = model.titleViewStyle
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.layoutToSuperview(axis: .horizontal, usesSafeAreaLayoutGuide: true)
        tableView.layoutToSuperview(axis: .vertical, usesSafeAreaLayoutGuide: true)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnnouncementTableViewCell.self)
        fiatBalanceCellProvider.registerFiatBalanceCell(for: tableView)
        tableView.registerNibCell(TotalBalanceTableViewCell.self, in: .module)
        tableView.registerNibCell(HistoricalBalanceTableViewCell.self, in: .module)
        tableView.register(HostingTableViewCell<WithdrawalLocksView>.self)
        tableView.separatorColor = .clear

        let refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.rx
            .controlEvent(.valueChanged)
            .bind(to: presenter.refreshRelay)
            .disposed(by: disposeBag)
        refreshControl.rx
            .controlEvent(.valueChanged)
            .map { false }
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        let dataSource = RxDataSource(
            animationConfiguration: .init(insertAnimation: .fade, reloadAnimation: .fade, deleteAnimation: .fade),
            configureCell: { [weak self] _, _, indexPath, item in
                guard let self = self else { return UITableViewCell() }
                let cell: UITableViewCell

                switch item {
                case .announcement(let model):
                    cell = self.announcementCell(for: indexPath, model: model)
                case .withdrawalLock:
                    cell = self.withdrawalLockCell(for: indexPath)
                case .fiatCustodialBalances(let presenter):
                    cell = self.fiatCustodialBalancesCell(for: indexPath, presenter: presenter)
                case .totalBalance(let presenter):
                    cell = self.balanceCell(for: indexPath, presenter: presenter)
                case .crypto(let presenter):
                    cell = self.assetCell(for: indexPath, presenter: presenter)
                case .cryptoSkeleton:
                    cell = self.assetCell(for: indexPath, presenter: nil)
                case .emptyState:
                    cell = self.emptyStateCell(for: indexPath)
                }
                cell.selectionStyle = .none
                return cell
            }
        )

        tableView.rx.modelSelected(PortfolioCellType.self)
            .bindAndCatch(weak: self) { (self, model) in
                switch model {
                case .announcement,
                     .totalBalance,
                     .withdrawalLock,
                     .cryptoSkeleton,
                     .fiatCustodialBalances,
                     .emptyState:
                    break
                case .crypto(let presenter):
                    self.presenter.router.showDetailsScreen(for: presenter.cryptoCurrency)
                }
            }
            .disposed(by: disposeBag)

        presenter.sections
            .observeOn(MainScheduler.asyncInstance)
            .bindAndCatch(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        presenter.isEmptyState
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak parent] isEmptyState in
                guard let buyButtonRenderer = parent as? BuyButtonViewRenderer else { return }
                buyButtonRenderer.render(buyButton: self.buyButton, isVisible: !isEmptyState)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    override public func navigationBarLeadingButtonPressed() {
        presenter.navigationBarLeadingButtonPressed()
    }

    // MARK: - Cells

    private func withdrawalLockCell(
        for indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeue(HostingTableViewCell<WithdrawalLocksView>.self, for: indexPath)
        let store = Store<WithdrawalLocksState, WithdrawalLocksAction>(
            initialState: .init(),
            reducer: withdrawalLocksReducer,
            environment: WithdrawalLocksEnvironment { [tableView] isVisible in
                tableView.beginUpdates()
                cell.updateRootView(height: isVisible ? 44 : 1)
                tableView.endUpdates()
            }
        )
        cell.host(WithdrawalLocksView(store: store), parent: self, height: 1)
        return cell
    }

    private func fiatCustodialBalancesCell(
        for indexPath: IndexPath,
        presenter: CurrencyViewPresenter
    ) -> UITableViewCell {
        fiatBalanceCellProvider.dequeueReusableFiatBalanceCell(
            for: tableView,
            indexPath: indexPath,
            presenter: presenter
        )
    }

    private func announcementCell(for indexPath: IndexPath, model: AnnouncementCardViewModel) -> UITableViewCell {
        let cell = tableView.dequeue(AnnouncementTableViewCell.self, for: indexPath)
        cell.viewModel = model
        return cell
    }

    private func balanceCell(for indexPath: IndexPath, presenter: TotalBalanceViewPresenter) -> UITableViewCell {
        let cell = tableView.dequeue(TotalBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter
        return cell
    }

    private func assetCell(for indexPath: IndexPath, presenter: HistoricalBalanceCellPresenter?) -> UITableViewCell {
        let cell = tableView.dequeue(HistoricalBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter
        return cell
    }

    private func emptyStateCell(for indexPath: IndexPath) -> UITableViewCell {
        PortfolioEmptyStateTableViewCell()
    }
}

extension PortfolioViewController: SegmentedViewScreenViewController {
    public func adjustInsetForBottomButton(withHeight height: CGFloat) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
    }
}
