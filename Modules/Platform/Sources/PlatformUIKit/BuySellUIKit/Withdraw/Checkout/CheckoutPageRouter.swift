// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RIBs

enum CheckoutRoute {
    case loading(amount: FiatValue)
    case confirmation(amount: FiatValue)
    case failure(CurrencyType, Error)
}

protocol CheckoutPageInteractable: Interactable, WithdrawalConfirmationRouting {
    var router: CheckoutPageRouting? { get set }
    var listener: CheckoutPageListener? { get set }
}

final class CheckoutPageRouter: ViewableRouter<CheckoutPageInteractable, ContentPageControllable>,
    CheckoutPageRouting
{

    private let confirmationPageBuilder: ConfirmationPageBuilder

    init(
        interactor: CheckoutPageInteractable,
        contentControllable: ContentPageControllable,
        confirmationBuilder: ConfirmationPageBuilder
    ) {
        confirmationPageBuilder = confirmationBuilder
        super.init(interactor: interactor, viewController: contentControllable)
        interactor.router = self
    }

    func route(to type: CheckoutRoute) {
        let controllable = controllable(for: type)
        viewController.transition(to: .render(controllable))
    }

    private func controllable(for type: CheckoutRoute) -> ViewControllable {
        switch type {
        case .loading(let amount):
            return confirmationPageBuilder.build(for: .loading(amount), routing: interactor)
        case .confirmation(let data):
            return confirmationPageBuilder.build(for: .success(data), routing: interactor)
        case .failure(let currencyType, let error):
            return confirmationPageBuilder.build(for: .failure(currencyType, error), routing: interactor)
        }
    }
}
