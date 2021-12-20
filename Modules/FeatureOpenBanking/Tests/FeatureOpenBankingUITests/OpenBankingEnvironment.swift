// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
import FeatureOpenBankingTestFixture
@testable import FeatureOpenBankingUI
import NetworkKit
import ToolKit

extension OpenBankingEnvironment {

    public static func test(
        scheduler: AnySchedulerOf<DispatchQueue> = DispatchQueue.test.eraseToAnyScheduler(),
        showTransferDetails: @escaping () -> Void = {},
        dismiss: @escaping () -> Void = {},
        openURL: @escaping (URL) -> Void = { _ in }
    ) -> (environment: OpenBankingEnvironment, network: ReplayNetworkCommunicator) {
        let (banking, network) = OpenBanking.test(using: scheduler)
        return (
            OpenBankingEnvironment(
                scheduler: scheduler,
                openBanking: banking,
                showTransferDetails: showTransferDetails,
                dismiss: dismiss,
                openURL: OpenURL(yield: openURL),
                fiatCurrencyFormatter: NoFormatCurrencyFormatter(),
                cryptoCurrencyFormatter: NoFormatCurrencyFormatter(),
                currency: "GBP"
            ),
            network
        )
    }
}
