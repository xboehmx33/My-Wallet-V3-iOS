// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import WalletPayloadKit

import Combine
import TestKit
import ToolKit
import XCTest

class WalletLogicTests: XCTestCase {

    private let jsonV4 = Fixtures.loadJSONData(filename: "wallet.v4", in: .module)!

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // TODO: Dimitris to fix
//    func test_wallet_logic_can_initialize_a_wallet() {
//        let walletHolder = WalletHolder()
//        var walletCreatorCalled = false
//        let walletCreator: WalletCreating = { blockchainWallet in
//            walletCreatorCalled = true
//            return { Wallet(from: blockchainWallet) }
//        }
//
//        let walletLogic = WalletLogic(holder: walletHolder, creator: walletCreator)
//
//        let expectation = expectation(description: "wallet holding")
//
//        walletLogic.initialize(using: jsonV4)
//            .sink { _ in
//                //
//            } receiveValue: { _ in
//                XCTAssertTrue(walletCreatorCalled)
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 2)
//
//        XCTAssertNotNil(walletHolder.wallet)
//    }
}
