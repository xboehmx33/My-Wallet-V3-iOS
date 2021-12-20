// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift
import ToolKit

protocol CheckoutPageRouting: AnyObject {
    func route(to type: CheckoutRoute)
}

protocol CheckoutPageListener: AnyObject {
    func closeFlow()
    func checkoutDidTapBack()
}

protocol CheckoutPagePresentable: Presentable {
    var continueButtonTapped: Signal<Void> { get }

    func connect(action: Driver<CheckoutPageInteractor.Action>) -> Driver<CheckoutPageInteractor.Effects>
}

final class CheckoutPageInteractor: PresentableInteractor<CheckoutPagePresentable>,
    CheckoutPageInteractable
{

    private typealias AnalyticsEvent = AnalyticsEvents.FiatWithdrawal

    weak var router: CheckoutPageRouting?
    weak var listener: CheckoutPageListener?

    private let checkoutData: WithdrawalCheckoutData
    private let withdrawalService: WithdrawalServiceAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI

    init(
        presenter: CheckoutPagePresentable,
        checkoutData: WithdrawalCheckoutData,
        withdrawalService: WithdrawalServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.checkoutData = checkoutData
        self.withdrawalService = withdrawalService
        self.analyticsRecorder = analyticsRecorder
        super.init(presenter: presenter)
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        analyticsRecorder.record(event: AnalyticsEvent.checkout(.shown(currencyCode: checkoutData.currency.code)))

        let checkoutDataAction = Driver.deferred { [weak self] () -> Driver<Action> in
            guard let self = self else { return .empty() }
            return .just(.load(self.checkoutData))
        }

        presenter.continueButtonTapped
            .asObservable()
            .do(onNext: { [analyticsRecorder, checkoutData] _ in
                analyticsRecorder.record(events: [
                    AnalyticsEvent.checkout(.confirm(currencyCode: checkoutData.currency.code)),
                    AnalyticsEvents.New.Withdrawal.withdrawalAmountEntered(
                        currency: checkoutData.currency.code,
                        inputAmount: checkoutData.amount.displayMajorValue.doubleValue,
                        outputAmount: checkoutData.amount.displayMajorValue.doubleValue -
                            checkoutData.fee.displayMajorValue.doubleValue,
                        withdrawalMethod: .bankAccount
                    )
                ])
            })
            .flatMapLatest(weak: self) { (self, _) -> Observable<Result<FiatValue, Error>> in
                self.withdrawalService.withdrawal(for: self.checkoutData)
                    .asObservable()
                    .observeOn(MainScheduler.asyncInstance)
                    .do(onSubscribe: {
                        self.router?.route(to: .loading(amount: self.checkoutData.amount))
                    })
            }
            .subscribe(onNext: { [analyticsRecorder, router] result in
                switch result {
                case .success(let amount):
                    analyticsRecorder.record(event: AnalyticsEvent.withdrawSuccess(currencyCode: self.checkoutData.currency.code))
                    router?.route(to: .confirmation(amount: amount))
                case .failure(let error):
                    analyticsRecorder.record(event: AnalyticsEvent.withdrawFailure(currencyCode: self.checkoutData.currency.code))
                    router?.route(to: .failure(self.checkoutData.currency.currencyType, error))
                }
            })
            .disposeOnDeactivate(interactor: self)

        presenter.connect(action: checkoutDataAction)
            .drive(onNext: handle(effect:))
            .disposeOnDeactivate(interactor: self)
    }

    func handle(effect: Effects) {
        switch effect {
        case .close:
            analyticsRecorder.record(event: AnalyticsEvent.checkout(.cancel(currencyCode: checkoutData.currency.code)))
            listener?.closeFlow()
        case .back:
            listener?.checkoutDidTapBack()
        }
    }

    func confirmationRequested(to route: WithdrawalConfirmationRoute) {
        switch route {
        case .closeFlow:
            handle(effect: .close)
        }
    }
}

extension CheckoutPageInteractor {
    enum Action: Equatable {
        case load(WithdrawalCheckoutData)
        case empty
    }

    enum Effects: Equatable {
        case close
        case back
    }
}
