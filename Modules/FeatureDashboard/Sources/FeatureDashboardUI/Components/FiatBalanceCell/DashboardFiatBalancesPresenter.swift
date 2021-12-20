// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit

import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift

final class DashboardFiatBalancesPresenter {

    // MARK: - Exposed Properties

    var tap: Driver<DashboardItemDisplayAction<CurrencyType>> {
        selectionRelay
            .asDriver()
    }

    /// Streams only distinct actions
    var action: Driver<DashboardItemDisplayAction<CurrencyViewPresenter>> {
        _ = setup
        return actionRelay
            .asDriver()
            .distinctUntilChanged()
    }

    // MARK: - Private Properties

    private let selectionRelay = BehaviorRelay<DashboardItemDisplayAction<CurrencyType>>(value: .hide)
    private let actionRelay = BehaviorRelay<DashboardItemDisplayAction<CurrencyViewPresenter>>(value: .hide)

    private let fiatBalancePresenter: CurrencyViewPresenter
    private let interactor: DashboardFiatBalancesInteractor
    private let disposeBag = DisposeBag()

    private lazy var setup: Void = {
        let fiatBalancePresenter = self.fiatBalancePresenter
        interactor.shouldAppear
            .map { $0 ? .show(fiatBalancePresenter) : .hide }
            .bindAndCatch(to: actionRelay)
            .disposed(by: disposeBag)
    }()

    // MARK: - Setup

    init(
        interactor: DashboardFiatBalancesInteractor,
        fiatBalancePresenter: FiatBalanceCollectionViewPresenting = resolve()
    ) {
        guard let fiatBalancePresenter = fiatBalancePresenter as? CurrencyViewPresenter else {
            fatalError("fiatBalancePresenter must conform to CurrencyViewPresenter")
        }
        self.interactor = interactor
        self.fiatBalancePresenter = fiatBalancePresenter

        fiatBalancePresenter
            .tap?
            .emit(onNext: { [weak self] currencyType in
                guard let self = self else { return }
                self.selectionRelay.accept(.show(currencyType))
            })
            .disposed(by: disposeBag)
    }

    func refresh() {
        interactor.refresh()
    }
}
