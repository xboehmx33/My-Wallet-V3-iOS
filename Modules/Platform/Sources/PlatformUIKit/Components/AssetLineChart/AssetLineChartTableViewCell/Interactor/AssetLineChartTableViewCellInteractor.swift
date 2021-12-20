// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Charts
import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift

final class AssetLineChartTableViewCellInteractor: AssetLineChartTableViewCellInteracting {

    // MARK: - AssetLineChartTableViewCellInteracting

    let lineChartUserInteractor: AssetLineChartUserInteracting
    let lineChartInteractor: AssetLineChartInteracting
    let assetPriceViewInteractor: AssetPriceViewInteracting
    let window = PublishRelay<PriceWindow>()
    var isDeselected: Driver<Bool> {
        isDeselectedRelay.asDriver()
    }

    // MARK: - Private Properties

    private let isDeselectedRelay = BehaviorRelay<Bool>(value: false)
    private let historicalFiatPriceService: HistoricalFiatPriceServiceAPI
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(
        cryptoCurrency: CryptoCurrency,
        fiatCurrencyService: FiatCurrencyServiceAPI,
        historicalFiatPriceService: HistoricalFiatPriceServiceAPI,
        lineChartView: LineChartView
    ) {
        self.historicalFiatPriceService = historicalFiatPriceService
        lineChartInteractor = AssetLineChartInteractor(
            cryptoCurrency: cryptoCurrency,
            fiatCurrencyService: fiatCurrencyService
        )
        lineChartUserInteractor = AssetLineChartUserInteractor(chartView: lineChartView)
        assetPriceViewInteractor = InstantAssetPriceViewInteractor(
            historicalPriceProvider: historicalFiatPriceService,
            chartUserInteracting: lineChartUserInteractor
        )

        lineChartUserInteractor
            .state
            .map { $0 == .deselected }
            .bindAndCatch(to: isDeselectedRelay)
            .disposed(by: disposeBag)

        // Bind window relay to the `PublishRelay<PriceWindow>` on
        // both the `AssetLineChartInteractor` and the `HistoricalFiatPriceService`.
        window
            .bindAndCatch(to: lineChartInteractor.priceWindowRelay)
            .disposed(by: disposeBag)

        window
            .bindAndCatch(to: historicalFiatPriceService.fetchTriggerRelay)
            .disposed(by: disposeBag)
    }
}
