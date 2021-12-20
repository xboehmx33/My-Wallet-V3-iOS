// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if DEBUG

import CombineSchedulers
import FeatureOpenBankingData
import Foundation
#if canImport(WalletNetworkKit)
import WalletNetworkKit
#else
import NetworkKit
#endif
import ToolKit

extension OpenBankingEnvironment {

    public static let mock = OpenBankingEnvironment(
        openBanking: .mock,
        openURL: ToLogAppOpener(),
        fiatCurrencyFormatter: NoFormatCurrencyFormatter(),
        cryptoCurrencyFormatter: NoFormatCurrencyFormatter(),
        currency: "GBP"
    )
}

extension OpenBanking {

    static let mock = OpenBanking(
        banking: OpenBankingClient.mock
    )
}

extension OpenBankingClient {

    static let mock = OpenBankingClient(
        requestBuilder: RequestBuilder(
            config: Network.Config(
                scheme: "https",
                host: "api.blockchain.info",
                components: ["nabu-gateway"]
            ),
            headers: [
                "Authorization": "Bearer ..."
            ]
        ),
        network: NetworkAdapter(
            communicator: EphemeralNetworkCommunicator()
        ).network
    )
}

extension OpenBanking.BankAccount {

    // swiftlint:disable:next force_try
    static var mock: Self = try! OpenBanking.BankAccount(
        json: [
            "id": "b0ae122f-e71e-4e6c-bc35-16ee64cdcc8f",
            "partner": "YAPILY",
            "attributes": [
                "institutions": [],
                "entity": "Safeconnect(UK)"
            ],
            "details": [
                "bankName": "Monzo",
                "sortCode": "040040",
                "accountNumber": "94936804"
            ]
        ]
    )
}

extension OpenBanking.Institution {

    // swiftlint:disable:next force_try
    static var mock: Self = try! OpenBanking.Institution(
        json: [
            "countries": [
                [
                    "countryCode2": "GB",
                    "displayName": "United Kingdom"
                ]
            ],
            "credentialsType": "OPEN_BANKING_UK_AUTO",
            "environmentType": "LIVE",
            "features": [],
            "fullName": "Monzo",
            "id": "monzo_ob",
            "media": [
                [
                    "source": "https://images.yapily.com/image/332bb781-3cc2-4f3e-ae79-1aba09fac991",
                    "type": "logo"
                ],
                [
                    "source": "https://images.yapily.com/image/f70dc041-c7a5-47d3-9c6b-846778eac01a",
                    "type": "icon"
                ]
            ],
            "name": "Monzo"
        ]
    )
}
#endif
