// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
import DIKit
import FeatureOpenBankingDomain
import NetworkKit
import SwiftUI
import ToolKit

public struct OpenBankingEnvironment {

    public var environment: Self { self }
    public private(set) var eventPublisher = PassthroughSubject<Result<Void, OpenBanking.Error>, Never>()

    public var scheduler: AnySchedulerOf<DispatchQueue>
    public var openBanking: OpenBanking
    public var showTransferDetails: () -> Void
    public var dismiss: () -> Void
    public var cancel: () -> Void
    public var openURL: URLOpener
    public var fiatCurrencyFormatter: FiatCurrencyFormatter
    public var cryptoCurrencyFormatter: CryptoCurrencyFormatter

    public init(
        scheduler: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler(),
        openBanking: OpenBanking = resolve(),
        showTransferDetails: @escaping () -> Void = {},
        dismiss: @escaping () -> Void = {},
        cancel: @escaping () -> Void = {},
        openURL: URLOpener = resolve(),
        fiatCurrencyFormatter: FiatCurrencyFormatter = resolve(),
        cryptoCurrencyFormatter: CryptoCurrencyFormatter = resolve(),
        currency: String
    ) {
        self.scheduler = scheduler
        self.openBanking = openBanking
        self.showTransferDetails = showTransferDetails
        self.dismiss = dismiss
        self.cancel = cancel
        self.openURL = openURL
        self.fiatCurrencyFormatter = fiatCurrencyFormatter
        self.cryptoCurrencyFormatter = cryptoCurrencyFormatter

        openBanking.state.set(.currency, to: currency)
    }
}
