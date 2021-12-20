// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Localization
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift
import ToolKit

struct ACHFlow {
    enum Screen {
        case selectMethod
        case addPaymentMethod(asInitialScreen: Bool)
    }
}

protocol ACHFlowRootRouting: Routing {
    // Declare methods the interactor can invoke to manage sub-tree via the router.
    func route(to screen: ACHFlow.Screen)
    func closeFlow()
}

protocol ACHFlowRootListener: AnyObject {
    // Declare methods the interactor can invoke to communicate with other RIBs.
}

final class ACHFlowRootInteractor: Interactor,
    ACHFlowRootInteractable,
    SelectPaymentMethodListener,
    AddNewPaymentMethodListener
{

    // MARK: - Injected

    weak var router: ACHFlowRootRouting?
    weak var listener: ACHFlowRootListener?

    private let stateService: StateServiceAPI
    private let paymentMethodService: SelectPaymentMethodService
    private let loadingViewPresenter: LoadingViewPresenting

    init(
        stateService: StateServiceAPI,
        paymentMethodService: SelectPaymentMethodService,
        loadingViewPresenter: LoadingViewPresenting = resolve()
    ) {
        self.stateService = stateService
        self.paymentMethodService = paymentMethodService
        self.loadingViewPresenter = loadingViewPresenter
        super.init()
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        paymentMethodService.paymentMethods
            .handleLoaderForLifecycle(loader: loadingViewPresenter, style: .circle)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { paymentMethods in
                if paymentMethods.isEmpty {
                    self.router?.route(to: .addPaymentMethod(asInitialScreen: true))
                } else {
                    self.router?.route(to: .selectMethod)
                }
            })
            .disposeOnDeactivate(interactor: self)
    }

    func closeFlow() {
        // this dismiss the navigation flow...
        stateService.previousRelay.accept(())
        router?.closeFlow()
    }

    func route(to screen: ACHFlow.Screen) {
        router?.route(to: screen)
    }

    func navigate(with method: PaymentMethod) {
        switch method.type {
        case .bankAccount:
            stateService.previousRelay.accept(())
            router?.closeFlow()
        case .bankTransfer:
            stateService.previousRelay.accept(())
            router?.closeFlow()
            stateService.nextFromBankLinkSelection()
        case .funds(.fiat(let currency)):
            showFundsTransferDetailsIfNeeded(for: currency)
        case .funds(.crypto):
            fatalError("Funds with crypto currency is not a possible state")
        case .card:
            stateService.nextFromCardLinkSelection()
        }
    }

    private func showFundsTransferDetailsIfNeeded(for currency: FiatCurrency) {
        paymentMethodService.isUserEligibleForFunds
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [stateService] isEligibile in
                if isEligibile {
                    stateService.showFundsTransferDetails(for: currency, isOriginDeposit: false)
                } else {
                    stateService.kyc()
                }
            }, onError: { error in
                Logger.shared.error(error)
            })
            .disposeOnDeactivate(interactor: self)
    }
}
