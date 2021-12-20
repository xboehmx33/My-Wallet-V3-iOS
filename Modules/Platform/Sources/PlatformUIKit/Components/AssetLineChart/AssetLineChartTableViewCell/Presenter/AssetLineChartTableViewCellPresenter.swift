// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Charts
import Localization
import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift

public final class AssetLineChartTableViewCellPresenter: AssetLineChartTableViewCellPresenting {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.Dashboard.AssetDetails

    // MARK: - AssetLineChartTableViewCellPresenting

    let presenterContainer: AssetLineChartPresenterContainer

    let lineChartView: LineChartView

    var window: Signal<PriceWindow> {
        windowRelay.asSignal()
    }

    private(set) lazy var priceWindowPresenter: MultiActionViewPresenting = MultiActionViewPresenter(
        segmentedViewModel: .default(
            items: priceWindowItems,
            defaultSelectedSegmentIndex: 1
        )
    )

    public var isScrollEnabled: Driver<Bool> {
        scrollingEnabledRelay.asDriver()
    }

    // MARK: - Private Properties

    private let scrollingEnabledRelay = BehaviorRelay(value: false)
    private let interactor: AssetLineChartTableViewCellInteracting
    private let cryptoCurrency: CryptoCurrency
    private let windowRelay = PublishRelay<PriceWindow>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    public init(
        cryptoCurrency: CryptoCurrency,
        fiatCurrencyService: FiatCurrencyServiceAPI,
        historicalFiatPriceService: HistoricalFiatPriceServiceAPI
    ) {
        self.cryptoCurrency = cryptoCurrency

        // Setup `lineChartView`
        lineChartView = LineChartView()
        lineChartView.chartDescription?.enabled = false
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.gridBackgroundColor = .clear
        lineChartView.borderColor = .clear
        lineChartView.xAxis.enabled = false
        lineChartView.leftAxis.enabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.minOffset = 0.0
        lineChartView.legend.enabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.pinchZoomEnabled = false
        lineChartView.data = LineChartData.empty

        interactor = AssetLineChartTableViewCellInteractor(
            cryptoCurrency: cryptoCurrency,
            fiatCurrencyService: fiatCurrencyService,
            historicalFiatPriceService: historicalFiatPriceService,
            lineChartView: lineChartView
        )

        presenterContainer = .init(
            priceViewPresenter: AssetPriceViewPresenter(
                interactor: interactor.assetPriceViewInteractor,
                alignment: .center,
                descriptors: .assetPrice(
                    accessibilityIdSuffix: cryptoCurrency.displayCode,
                    priceFontSize: 32.0,
                    changeFontSize: 14.0
                )
            ),
            lineChartPresenter: .init(edge: 0.0, interactor: interactor.lineChartInteractor),
            lineChartView: lineChartView
        )

        interactor
            .isDeselected
            .drive(scrollingEnabledRelay)
            .disposed(by: disposeBag)

        windowRelay
            .bindAndCatch(to: interactor.window)
            .disposed(by: disposeBag)
    }

    private func setup() {
        window
            .emit(onNext: { [weak self] priceWindow in
                guard let self = self else { return }
                self.windowRelay.accept(priceWindow)
            })
            .disposed(by: disposeBag)
    }

    private lazy var priceWindowItems: [SegmentedViewModel.Item] = {
        [
            .text(
                LocalizedString.day,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.windowRelay.accept(.day(.fifteenMinutes))
                }
            ),
            .text(
                LocalizedString.week,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.windowRelay.accept(.week(.oneHour))
                }
            ),
            .text(
                LocalizedString.month,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.windowRelay.accept(.month(.twoHours))
                }
            ),
            .text(
                LocalizedString.year,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.windowRelay.accept(.year(.oneDay))
                }
            ),
            .text(
                LocalizedString.all,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.windowRelay.accept(.all(.fiveDays))
                }
            )
        ]
    }()
}
