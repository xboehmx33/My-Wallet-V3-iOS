// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import WalletPayloadKit

import Combine
import TestKit
import ToolKit
import XCTest

class WalletHolderTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // TODO: Dimitris to fix
//    func test_initializing_wallet_holder_should_provide_wallet_nil() {
//        let holder = WalletHolder()
//        XCTAssertNil(holder.wallet.value)
//        XCTAssertNil(holder.provideWallet())
//    }
//
//    func test_wallet_holder_can_hold_and_create_a_wallet_using_factory_method() {
//        let holder = WalletHolder()
//
//        let blockchainWallet = BlockchainWallet(
//            guid: "",
//            sharedKey: "",
//            doubleEncryption: false,
//            doublePasswordHash: nil,
//            metadataHDNode: "",
//            options: Options(pbkdf2Iterations: 0, feePerKB: 0, html5Notifications: false, logoutTime: 0),
//            addresses: [],
//            hdWallets: []
//        )
//        var walletProviderCalled = false
//        let walletProvider: ProvideWallet = {
//            walletProviderCalled = true
//            return Wallet(from: blockchainWallet)
//        }
//
//        let expectation = expectation(description: "wallet holding")
//        holder.hold(using: walletProvider)
//            .sink { _ in
//                //
//            } receiveValue: { _ in
//                XCTAssert(walletProviderCalled)
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 2)
//
//        XCTAssertNotNil(holder.wallet)
//    }
//
//    func test_wallet_holder_can_release_an_previous_created_wallet_object() {
//        let holder = WalletHolder()
//
//        let blockchainWallet = BlockchainWallet(
//            guid: "",
//            sharedKey: "",
//            doubleEncryption: false,
//            doublePasswordHash: nil,
//            metadataHDNode: "",
//            options: Options(pbkdf2Iterations: 0, feePerKB: 0, html5Notifications: false, logoutTime: 0),
//            addresses: [],
//            hdWallets: []
//        )
//        let walletProvider: ProvideWallet = {
//            Wallet(from: blockchainWallet)
//        }
//
//        let expectation = expectation(description: "wallet holding")
//        // given
//        holder.hold(using: walletProvider)
//            .sink { _ in
//                //
//            } receiveValue: { _ in
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
//        wait(for: [expectation], timeout: 2)
//
//        // verify that wallet exists
//        XCTAssertNotNil(holder.wallet)
//
//        // when
//        holder.release()
//
//        // then
//        XCTAssertNil(holder.wallet.value)
//    }
}
