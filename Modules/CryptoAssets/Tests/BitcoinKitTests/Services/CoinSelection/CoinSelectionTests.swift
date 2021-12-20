// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
@testable import BitcoinKit
import MoneyKit
import PlatformKit
import XCTest

class CoinSelectionTests: XCTestCase {

    private static let feePerByte = BigUInt(55)

    var fee: Fee!
    var calculator: TransactionSizeCalculating!
    var subject: CoinSelection!

    override func setUp() {
        super.setUp()

        fee = Fee(feePerByte: CoinSelectionTests.feePerByte)
        calculator = TransactionSizeCalculator()
        subject = CoinSelection(calculator: calculator)
    }

    override func tearDown() {
        fee = nil
        calculator = nil
        subject = nil

        super.tearDown()
    }

    func test_ascent_draw_selection_with_change_output() throws {
        let outputAmount = try BitcoinValue(crypto: CryptoValue(amount: 100000, currency: .coin(.bitcoin)))
        let coins = unspents([1, 20000, 0, 0, 300000, 50000, 30000])
        let strategy = AscentDrawSortingStrategy()
        let result = subject.select(inputs:
            CoinSelectionInputs(
                value: outputAmount,
                fee: fee,
                unspentOutputs: coins,
                sortingStrategy: strategy
            )
        )

        let selected = unspents([20000, 30000, 50000, 300000])
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: selected,
            absoluteFee: BigUInt(37070),
            consumedAmount: BigUInt.zero
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_ascent_draw_selection_with_no_change_output() throws {
        let outputAmount = try BitcoinValue(crypto: CryptoValue(amount: 472000, currency: .coin(.bitcoin)))
        let coins = unspents([200000, 300000, 500000])
        let strategy = AscentDrawSortingStrategy()
        let result = subject.select(inputs:
            CoinSelectionInputs(
                value: outputAmount,
                fee: fee,
                unspentOutputs: coins,
                sortingStrategy: strategy
            )
        )
        let selected = unspents([200000, 300000])
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: selected,
            absoluteFee: selected.sum() - outputAmount.amount.magnitude,
            consumedAmount: BigUInt(9190)
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_descent_draw_selection_with_change_output() throws {
        let outputAmount = try BitcoinValue(crypto: CryptoValue(amount: 100000, currency: .coin(.bitcoin)))
        let coins = unspents([1, 20000, 0, 0, 300000, 50000, 30000])
        let strategy = DescentDrawSortingStrategy()
        let result = subject.select(inputs:
            CoinSelectionInputs(
                value: outputAmount,
                fee: fee,
                unspentOutputs: coins,
                sortingStrategy: strategy
            )
        )
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: unspents([300000]),
            absoluteFee: BigUInt(12485),
            consumedAmount: BigUInt.zero
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_descent_draw_selection_with_no_change_output() throws {
        let outputAmount = try BitcoinValue(crypto: CryptoValue(amount: 485000, currency: .coin(.bitcoin)))
        let coins = unspents([200000, 300000, 500000])
        let strategy = DescentDrawSortingStrategy()
        let result = subject.select(inputs:
            CoinSelectionInputs(
                value: outputAmount,
                fee: fee,
                unspentOutputs: coins,
                sortingStrategy: strategy
            )
        )
        let selected = unspents([500000])
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: selected,
            absoluteFee: selected.sum() - outputAmount.amount.magnitude,
            consumedAmount: BigUInt(4385)
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_select_all_selection_with_effective_inputs() throws {
        let coins = unspents([1, 20000, 0, 0, 300000])
        let result = subject.select(all: coins, fee: fee)
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: unspents([20000, 300000]),
            absoluteFee: BigUInt(18810),
            consumedAmount: BigUInt.zero
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_select_all_selection_with_no_inputs() throws {
        let coins = unspents([])
        let result = subject.select(all: coins, fee: fee)
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: unspents([]),
            absoluteFee: BigUInt.zero,
            consumedAmount: BigUInt.zero
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }

    func test_select_all_selection_with_no_effective_inputs() throws {
        let coins = unspents([1, 10, 100])
        let result = subject.select(all: coins, fee: fee)
        let expectedOutputs = SpendableUnspentOutputs(
            spendableOutputs: unspents([]),
            absoluteFee: BigUInt.zero,
            consumedAmount: BigUInt.zero
        )
        let outputs = try result.get()
        XCTAssertEqual(outputs, expectedOutputs)
    }
}

private func unspents(_ values: [Int]) -> [UnspentOutput] {
    values.compactMap { value in
        let absolute = abs(value)
        let cryptoValue = CryptoValue(amount: BigInt(absolute), currency: .coin(.bitcoin))
        guard let bitcoinValue = try? BitcoinValue(crypto: cryptoValue) else {
            return nil
        }
        return UnspentOutput.create(with: bitcoinValue)
    }
}

extension UnspentOutput {
    static func create(
        with value: BitcoinValue,
        hash: String = "hash",
        script: String = "script",
        confirmations: UInt = 0,
        transactionIndex: Int = 0,
        xpub: XPub = XPub(m: "m", path: "path"),
        isReplayable: Bool = true,
        isForceInclude: Bool = false
    ) -> UnspentOutput {
        UnspentOutput(
            hash: hash,
            script: script,
            value: value,
            confirmations: confirmations,
            transactionIndex: transactionIndex,
            xpub: xpub,
            isReplayable: isReplayable,
            isForceInclude: isForceInclude
        )
    }
}
