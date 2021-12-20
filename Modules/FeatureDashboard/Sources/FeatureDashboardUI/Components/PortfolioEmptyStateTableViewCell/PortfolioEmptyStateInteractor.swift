// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxSwift

final class PortfolioEmptyStateInteractor {

    private let disposeBag: DisposeBag = .init()
    private let tabSwapping: TabSwapping
    private let walletOperations: WalletOperationsRouting
    private let depositRouter: CashIdentityVerificationAnnouncementRouting

    init(
        tabSwapping: TabSwapping = resolve(),
        walletOperations: WalletOperationsRouting = resolve(),
        depositRouter: CashIdentityVerificationAnnouncementRouting = resolve()
    ) {
        self.tabSwapping = tabSwapping
        self.walletOperations = walletOperations
        self.depositRouter = depositRouter
    }

    func handleDeposit() {
        depositRouter.showCashIdentityVerificationScreen()
    }

    func switchTabToReceive() {
        tabSwapping.switchTabToReceive()
    }

    func handleBuy() {
        walletOperations.handleBuyCrypto(currency: .coin(.bitcoin))
    }
}
