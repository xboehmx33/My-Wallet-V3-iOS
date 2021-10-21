// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
import DIKit
import NetworkKit
import OpenBanking
import SwiftUI
import ToolKit

public struct OpenBankingEnvironment {

    public var environment: Self { self }
    public private(set) var event$ = PassthroughSubject<OpenBankingEvent, Never>()

    public var scheduler: Scheduler
    public var openBanking: OpenBanking
    public var showTransferDetails: () -> Void
    public var dismiss: () -> Void
    public var openURL: URLOpener
    public var fiatCurrencyFormatter: FiatCurrencyFormatter

    public init(
        scheduler: Scheduler = .init(),
        openBanking: OpenBanking = resolve(),
        showTransferDetails: @escaping () -> Void = {},
        dismiss: @escaping () -> Void = {},
        openURL: URLOpener = resolve(),
        fiatCurrencyFormatter: FiatCurrencyFormatter = resolve(),
        currency: String
    ) {
        self.scheduler = scheduler
        self.openBanking = openBanking
        self.showTransferDetails = showTransferDetails
        self.dismiss = dismiss
        self.openURL = openURL
        self.fiatCurrencyFormatter = fiatCurrencyFormatter

        openBanking.state.set(.currency, to: currency)
    }
}

extension OpenBankingEnvironment {

    public struct Scheduler {

        public var main: AnySchedulerOf<DispatchQueue>
        public var background: AnySchedulerOf<DispatchQueue>

        public init(
            main: AnySchedulerOf<DispatchQueue> = .main,
            background: AnySchedulerOf<DispatchQueue> = .init(
                DispatchQueue(label: "com.blockchain.open-banking.background")
            )
        ) {
            self.main = main
            self.background = background
        }
    }
}
