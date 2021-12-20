// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

final class CheckoutPageDetailsPresenter: DetailsScreenPresenterAPI, CheckoutPagePresentable {
    // MARK: - Navigation Properties

    let reloadRelay = PublishRelay<Void>()
    let titleViewRelay = BehaviorRelay<Screen.Style.TitleView>(value: .none)
    let navigationBarLeadingButtonAction: DetailsScreen.BarButtonAction
    let navigationBarTrailingButtonAction: DetailsScreen.BarButtonAction

    var navigationBarAppearance: DetailsScreen.NavigationBarAppearance {
        .custom(
            leading: .back,
            trailing: .none,
            barStyle: .darkContent(ignoresStatusBar: false, background: .white)
        )
    }

    // MARK: - Actions

    var continueButtonTapped: Signal<Void> {
        continueButtonPressed.asSignal()
    }

    // MARK: - Screen Properties

    private(set) var buttons: [ButtonViewModel] = []
    private(set) var cells: [DetailsScreen.CellType] = []

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()
    private let navigationCloseRelay = PublishRelay<Void>()
    private let backButtonPressed = PublishRelay<Void>()
    private let cancelButtonPressed = PublishRelay<Void>()
    private let continueButtonPressed = PublishRelay<Void>()

    // MARK: - Injected

    private let fiatCurrency: FiatCurrency
    private let analyticsRecorder: AnalyticsEventRecorderAPI

    init(
        fiatCurrency: FiatCurrency,
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.fiatCurrency = fiatCurrency
        self.analyticsRecorder = analyticsRecorder

        navigationBarTrailingButtonAction = .default
        navigationBarLeadingButtonAction = .custom { [backButtonPressed] in
            backButtonPressed.accept(())
        }
    }

    func connect(action: Driver<CheckoutPageInteractor.Action>) -> Driver<CheckoutPageInteractor.Effects> {
        let details = action
            .distinctUntilChanged()
            .flatMap { action -> Driver<WithdrawalCheckoutData> in
                guard case .load(let data) = action else {
                    return .empty()
                }
                return .just(data)
            }

        details
            .drive(weak: self, onNext: { (self, data) in
                self.setup(checkoutData: data)
            })
            .disposed(by: disposeBag)

        let closeTapped = cancelButtonPressed
            .map { CheckoutPageInteractor.Effects.close }
            .asDriverCatchError()

        let backTapped = backButtonPressed
            .map { CheckoutPageInteractor.Effects.back }
            .asDriverCatchError()

        return .merge(closeTapped, backTapped)
    }

    private func setup(checkoutData: WithdrawalCheckoutData) {
        let contentReducer = CheckoutPageContentReducer(data: checkoutData)

        titleViewRelay.accept(.text(value: contentReducer.title))

        buttons = [
            contentReducer.cancelButtonViewModel,
            contentReducer.continueButtonViewModel
        ]

        contentReducer.cancelButtonViewModel
            .tap
            .emit(to: cancelButtonPressed)
            .disposed(by: disposeBag)

        contentReducer.continueButtonViewModel
            .tap
            .emit(to: continueButtonPressed)
            .disposed(by: disposeBag)

        cells = contentReducer.cells

        reloadRelay.accept(())
    }
}
