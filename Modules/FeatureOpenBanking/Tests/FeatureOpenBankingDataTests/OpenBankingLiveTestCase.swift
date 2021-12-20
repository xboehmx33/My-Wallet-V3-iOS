// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CombineSchedulers
@testable import FeatureOpenBankingData
@testable import NetworkKit
import TestKit

/// Used for testing without any UI
final class OpenBankingLiveTestCase: XCTestCase {

    var banking: OpenBankingClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        banking = OpenBankingClient(
            requestBuilder: RequestBuilder(
                config: Network.Config(
                    scheme: "https",
                    host: "api.blockchain.info",
                    components: ["nabu-gateway"]
                ),
                headers: [
                    "Authorization": "Bearer "
                ]
            ),
            network: NetworkAdapter(
                communicator: EphemeralNetworkCommunicator(
                    isRecording: true,
                    directory: "/tmp/OpenBanking"
                )
            ).network,
            scheduler: DispatchQueue.main.eraseToAnyScheduler(),
            state: .init([.currency: "GBP"])
        )
    }

    func x_test_delete() throws {

        let accounts = try banking.fetchAllBankAccounts()
            .wait(timeout: 5)

        for account in accounts where account.state != .active {
            print("Deleting \(account.id.value)", terminator: " ")
            switch Result(catching: { try account.delete(in: banking).wait() }) {
            case .failure(let error):
                print("❌ \(error)")
            case .success:
                print("✅")
            }
        }
    }

    func x_test_link() throws {

        let bankAccount = try banking.createBankAccount()
            .wait(timeout: 5)

        let activation = try bankAccount.activateBankAccount(
            with: bankAccount.attributes.institutions![1].id,
            in: banking
        )
        .wait(timeout: 5)

        let subscription = banking.state.publisher(for: .authorisation.url, as: URL.self).sink { result in
            switch result {
            case .success(let url):
                var consentToken = ""
                // Stop debugger on `print` and set `consentToken`
                // to mutate the open banking state to finalise the transaction
                consentToken = ""
                print(url) // e consentToken = "..."
                self.banking.state.set(.consent.token, to: consentToken)
            case .failure(.keyDoesNotExist):
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        let account = try activation.poll(in: banking)
            .wait(timeout: 120000)

        subscription.cancel()
        _ = account
    }

    func x_test_payment() throws {

        let bankAccount = try banking.fetchAllBankAccounts()
            .wait(timeout: 5)
            .first(where: { $0.state == "ACTIVE" })
            .unwrap()

        let payment = try bankAccount.deposit(amountMinor: "1000", product: "SIMPLEBUY", in: banking)
            .wait(timeout: 5)

        let subscription = banking.state.publisher(for: .authorisation.url, as: URL.self).sink { result in
            switch result {
            case .success(let url):
                var consentToken = ""
                // Stop debugger on `print` and set `consentToken`
                // to mutate the open banking state to finalise the transaction
                consentToken = ""
                print(url) // e consentToken = "..."
                self.banking.state.set(.consent.token, to: consentToken)
            case .failure(.keyDoesNotExist):
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        let details = try payment.poll(in: banking)
            .wait(timeout: 120000)

        subscription.cancel()
        _ = details
    }
}
