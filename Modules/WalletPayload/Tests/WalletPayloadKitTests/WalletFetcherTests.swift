// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import WalletPayloadKit

import Combine
import TestKit
import ToolKit
import XCTest

class WalletFetcherTests: XCTestCase {

    let jsonV4 = Fixtures.loadJSONData(filename: "wallet-wrapper-v4", in: .module)!

    private var cancellables: Set<AnyCancellable>!
    private var walletRepo: WalletRepo!

    override func setUp() {
        super.setUp()
        walletRepo = WalletRepo(initialState: .empty)
        cancellables = []
    }

    // TODO: Dimitris to fix
//    func test_wallet_fetcher_is_able_to_fetch_using_password() throws {
//        // skip test until it is finalized and working
//        try XCTSkipIf(true)
//
//        let dispatchQueue = DispatchQueue(label: "wallet.fetcher.op-queue")
//        let payloadCrypto = PayloadCrypto(cryptor: AESCryptor())
//        let walletHolder = WalletHolder()
//        let walletLogic = WalletLogic(holder: walletHolder, creator: createWallet(from:))
//        let walletFetcher = WalletFetcher(
//            walletRepo: walletRepo,
//            payloadCrypto: payloadCrypto,
//            walletLogic: walletLogic,
//            operationsQueue: dispatchQueue
//        )
//
//        let encryptedPayload = try JSONDecoder().decode(WalletPayloadWrapper.self, from: jsonV4)
//        walletRepo.set(
//            keyPath: \.encryptedPayload,
//            value: encryptedPayload
//        )
//        var receivedValue: EmptyValue?
//        var error: Error?
//        let expectation = expectation(description: "wallet-fetching-expectation")
//
//        walletFetcher.fetch(using: "misura12!")
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let failureError):
//                    error = failureError
//                }
//            } receiveValue: { value in
//                receivedValue = value
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
//        waitForExpectations(timeout: 2)
//
//        XCTAssertNotNil(walletHolder.wallet)
//        XCTAssertEqual(receivedValue, .noValue)
//        XCTAssertNil(error)
//    }
}
