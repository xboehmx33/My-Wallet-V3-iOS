// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift
import UIKit

/// Provides the entry point for `SelectLinkedBanksRouter`
protocol LinkedBanksSelectionBuildable {
    func build(listener: LinkedBanksSelectionListener) -> LinkedBanksSelectionRouter
}

final class LinkedBanksSelectionBuilder: LinkedBanksSelectionBuildable {

    private let currency: FiatCurrency

    init(currency: FiatCurrency) {
        self.currency = currency
    }

    func build(listener: LinkedBanksSelectionListener) -> LinkedBanksSelectionRouter {
        let viewController = LinkedBanksSelectionViewController()
        let interactor = LinkedBanksSelectionInteractor(
            presenter: viewController,
            currency: currency
        )
        interactor.listener = listener
        let addNewBankAccountBuilder = AddNewBankAccountBuilder(
            currency: currency,
            isOriginDeposit: false
        )
        let router = LinkedBanksSelectionRouter(
            interactor: interactor,
            viewController: viewController,
            addNewBankBuilder: addNewBankAccountBuilder
        )
        return router
    }
}
