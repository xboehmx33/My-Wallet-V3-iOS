// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Localization
import PlatformKit
import PlatformUIKit
import RIBs
import RxCocoa
import RxDataSources
import RxSwift
import ToolKit
import UIKit

protocol SwapLandingPresentableListener: AnyObject {
    func newSwap(withPair pair: SwapTrendingPair?)
}

final class SwapLandingViewController: BaseTableViewController, SwapLandingPresentable, SwapLandingViewControllable {

    private typealias RxDataSource = RxTableViewSectionedReloadDataSource<SwapLandingSectionModel>
    private typealias LocalizationIds = LocalizationConstants.Swap

    private let headerRelay = BehaviorRelay<HeaderBuilder?>(value: nil)
    private var disposeBag = DisposeBag()

    weak var listener: SwapLandingPresentableListener?

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        title = LocalizationIds.swap
        set(
            barStyle: .lightContent(),
            leadingButtonStyle: .drawer,
            trailingButtonStyle: .qrCode
        )
    }

    func connect(state: Driver<SwapLandingScreenState>) -> Driver<SwapLandingSelectionEffects> {
        disposeBag = DisposeBag()
        let stateWait: Driver<SwapLandingScreenState> =
            rx.viewDidLoad
                .asDriver()
                .flatMap { _ in
                    state
                }

        let items: Driver<[SwapLandingSectionModel]> = stateWait
            .map(\.action)
            .flatMap { action in
                switch action {
                case .items(let viewModels):
                    return .just(viewModels)
                }
            }

        stateWait
            .map(\.header)
            .map { AccountPickerHeaderBuilder(headerType: .default($0)) }
            .drive(headerRelay)
            .disposed(by: disposeBag)

        let dataSource = RxDataSource(
            configureCell: { [weak self] _, _, indexPath, item -> UITableViewCell in
                guard let self = self else { return UITableViewCell() }
                switch item {
                case .pair(let viewModel):
                    return self.swapTrendingTableViewCell(viewModel: viewModel, for: indexPath.row)
                case .separator:
                    return self.separatorCell(for: indexPath.row)
                }
            }
        )

        items
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        let tap = setupButtonView()

        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)

        /// Effects
        let cellSelected = tableView.rx
            .modelSelected(SwapLandingSectionItem.self)
            .map { item -> SwapLandingSelectionEffects in
                switch item {
                case .pair(let viewModel):
                    return .swap(viewModel.trendingPair)
                case .separator:
                    return .none
                }
            }
            .asDriver(onErrorJustReturn: .none)

        return Driver.merge(cellSelected, tap)
            .asDriver(onErrorJustReturn: .none)
    }

    @objc private func didTapNewSwap() {
        listener?.newSwap(withPair: nil)
    }

    private func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.selfSizingBehaviour = .fill
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 156
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.register(SwapTrendingPairTableViewCell.self)
        tableView.register(SeparatorTableViewCell.self)
    }

    private func setupButtonView() -> Driver<SwapLandingSelectionEffects> {
        let viewModel: ButtonViewModel = .primary(with: LocalizationIds.Trending.newSwap)
        addButton(with: viewModel)
        return viewModel
            .tap
            .flatMap { _ in Driver.just(SwapLandingSelectionEffects.newSwap) }
    }

    // MARK: - Accessors

    private func swapTrendingTableViewCell(viewModel: SwapTrendingPairViewModel, for row: Int) -> UITableViewCell {
        let cell = tableView.dequeue(
            SwapTrendingPairTableViewCell.self,
            for: IndexPath(row: row, section: 0)
        )
        cell.viewModel = viewModel
        return cell
    }

    private func separatorCell(for row: Int) -> UITableViewCell {
        tableView.dequeue(SeparatorTableViewCell.self, for: IndexPath(row: row, section: 0))
    }
}

extension SwapLandingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        return headerRelay.value?.view(fittingWidth: view.bounds.width, customHeight: nil)
    }
}
