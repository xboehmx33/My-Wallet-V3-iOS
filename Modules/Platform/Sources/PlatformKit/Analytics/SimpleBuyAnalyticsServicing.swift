//
//  SimpleBuyAnalyticsServicing.swift
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import MoneyKit
import RxRelay

public protocol SimpleBuyAnalayticsServicing {

    func bind(_ relay: PublishRelay<Void>)
    func recordCustodyWalletCardShownEvent()
    func recordTradingWalletClicked(for currency: CryptoCurrency)
}
