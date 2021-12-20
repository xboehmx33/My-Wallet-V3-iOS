// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

enum SelectPaymentMethodAction {
    case items([PaymentMethodCellModel])
}

enum SelectPaymentMethodEffects {
    case addNewPaymentMethod
    case closeFlow
}

protocol SelectPaymentMethodRouting: ViewableRouting {
    // Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol SelectPaymentMethodPresentable: Presentable {
    func connect(action: Driver<SelectPaymentMethodAction>) -> Driver<SelectPaymentMethodEffects>
}

protocol SelectPaymentMethodListener: AnyObject {
    func closeFlow()
    func route(to screen: ACHFlow.Screen)
}

final class SelectPaymentMethodInteractor: PresentableInteractor<SelectPaymentMethodPresentable>, SelectPaymentMethodInteractable {
    // MARK: - Types

    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy

    // MARK: - Injected

    weak var router: SelectPaymentMethodRouting?
    weak var listener: SelectPaymentMethodListener?

    private let paymentMethodService: SelectPaymentMethodService
    private let loadingViewPresenter: LoadingViewPresenting
    private let eventRecorder: AnalyticsEventRecorderAPI

    private let selectionRelay = PublishRelay<PaymentMethodType>()

    init(
        presenter: SelectPaymentMethodPresentable,
        paymentMethodService: SelectPaymentMethodService,
        loadingViewPresenter: LoadingViewPresenting = resolve(),
        eventRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.paymentMethodService = paymentMethodService
        self.loadingViewPresenter = loadingViewPresenter
        self.eventRecorder = eventRecorder
        super.init(presenter: presenter)
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        let methods = paymentMethodService.paymentMethods
            .handleLoaderForLifecycle(loader: loadingViewPresenter, style: .circle)
            .map { [weak self] (methods: [PaymentMethodType]) -> [PaymentMethodCellViewModelItem] in
                guard let self = self else { return [] }
                let methodCells = methods.compactMap { type in
                    self.generateCellType(by: type) ?? nil
                }
                let addNewCell = self.generateAddNewCell()
                return methodCells + [addNewCell]
            }
            .map { [PaymentMethodCellModel(items: $0)] }
            .map { SelectPaymentMethodAction.items($0) }
            .asDriver(onErrorDriveWith: .empty())

        let selectedPaymentMethod = selectionRelay
            .share(replay: 1, scope: .whileConnected)

        selectedPaymentMethod
            .subscribe { method in
                self.paymentMethodService.select(method: method)
            }
            .disposeOnDeactivate(interactor: self)

        selectedPaymentMethod
            .map { _ in SelectPaymentMethodEffects.closeFlow }
            .asDriverCatchError()
            .drive(onNext: handle(effect:))
            .disposeOnDeactivate(interactor: self)

        let actions = Driver.merge(methods)
        presenter.connect(action: actions)
            .drive(onNext: handle(effect:))
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
    }

    // MARK: - Private

    private func handle(effect: SelectPaymentMethodEffects) {
        switch effect {
        case .closeFlow:
            listener?.closeFlow()
        case .addNewPaymentMethod:
            listener?.route(to: .addPaymentMethod(asInitialScreen: false))
        }
    }

    // MARK: - Private

    private func generateCellType(by paymentMethodType: PaymentMethodType) -> PaymentMethodCellViewModelItem? {
        var cellType: PaymentMethodCellViewModelItem?
        switch paymentMethodType {
        case .suggested:
            break
        case .card(let cardData):
            let presenter = LinkedCardCellPresenter(
                acceptsUserInteraction: true,
                cardData: cardData
            )
            presenter.tap
                .do(onNext: { [weak self] _ in
                    self?.eventRecorder.record(events: [
                        AnalyticsEvent.sbPaymentMethodSelected(selection: .card),
                        AnalyticsEvents.New.SimpleBuy.buyPaymentMethodSelected(paymentType: .paymentCard)
                    ])
                })
                .map { _ in paymentMethodType }
                .emit(to: selectionRelay)
                .disposeOnDeactivate(interactor: self)
            cellType = .linkedCard(presenter)
        case .account(let data):
            let presenter = FiatCustodialBalanceViewPresenter(
                interactor: FiatCustodialBalanceViewInteractor(balance: data.topLimit.moneyValue),
                descriptors: .paymentMethods(),
                respondsToTaps: true,
                presentationStyle: .plain
            )
            presenter.tap
                .do(onNext: { [weak self] _ in
                    self?.eventRecorder.record(events: [
                        AnalyticsEvent.sbPaymentMethodSelected(selection: .funds),
                        AnalyticsEvents.New.SimpleBuy.buyPaymentMethodSelected(paymentType: .funds)
                    ])
                })
                .map { _ in paymentMethodType }
                .emit(to: selectionRelay)
                .disposeOnDeactivate(interactor: self)
            cellType = .account(presenter)
        case .linkedBank(let data):
            let viewModel = LinkedBankViewModel(data: data)
            viewModel.tap
                .do(onNext: { [weak self] _ in
                    self?.eventRecorder.record(events: [
                        AnalyticsEvent.sbPaymentMethodSelected(selection: .funds),
                        AnalyticsEvents.New.SimpleBuy.buyPaymentMethodSelected(paymentType: .funds)
                    ])
                })
                .map { _ in paymentMethodType }
                .emit(to: selectionRelay)
                .disposeOnDeactivate(interactor: self)
            cellType = .linkedBank(viewModel)
        }

        return cellType
    }

    private func generateAddNewCell() -> PaymentMethodCellViewModelItem {
        let model = AddNewPaymentMethodCellModel()
        model.tap
            .map { _ in SelectPaymentMethodEffects.addNewPaymentMethod }
            .emit(onNext: handle(effect:))
            .disposeOnDeactivate(interactor: self)
        return PaymentMethodCellViewModelItem.addNew(model)
    }
}
