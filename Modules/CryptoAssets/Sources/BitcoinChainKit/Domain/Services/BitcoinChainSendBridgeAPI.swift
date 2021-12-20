// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

public struct BitcoinChainTransactionProposal<Token: BitcoinChainToken> {
    public let destination: BitcoinChainReceiveAddress<Token>
    public let amount: MoneyValue
    public let fees: MoneyValue
    public let walletIndex: Int32
    public let source: CryptoAccount

    public var coin: BitcoinChainCoin {
        Token.coin
    }

    public init(
        destination: BitcoinChainReceiveAddress<Token>,
        amount: MoneyValue,
        fees: MoneyValue,
        walletIndex: Int32,
        source: CryptoAccount
    ) {
        self.destination = destination
        self.amount = amount
        self.fees = fees
        self.walletIndex = walletIndex
        self.source = source
    }
}

public struct BitcoinChainTransactionCandidate<Token: BitcoinChainToken> {
    public let destination: BitcoinChainReceiveAddress<Token>
    public let amount: MoneyValue
    public let fees: MoneyValue
    public let source: CryptoAccount
    public let sweepFee: MoneyValue
    public let sweepAmount: MoneyValue

    public init(proposal: BitcoinChainTransactionProposal<Token>, fees: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue) {
        destination = proposal.destination
        amount = proposal.amount
        source = proposal.source
        self.fees = fees
        self.sweepFee = sweepFee
        self.sweepAmount = sweepAmount
    }
}

public enum BitcoinChainTransactionError: Error {
    case belowDustThreshold(finalFee: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue)
    case noUnspentOutputs(finalFee: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue)
    case feeTooLow(finalFee: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue)
    case unknown(finalFee: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue)

    public init(stringValue: String, finalFee: MoneyValue, sweepAmount: MoneyValue, sweepFee: MoneyValue) {
        switch stringValue {
        case let x where x.contains("BELOW_DUST_THRESHOLD"):
            self = .belowDustThreshold(finalFee: finalFee, sweepAmount: sweepAmount, sweepFee: sweepFee)
        case let x where x.contains("NO_UNSPENT_OUTPUTS"),
             let x where x.contains("No free outputs to spend"):
            self = .noUnspentOutputs(finalFee: finalFee, sweepAmount: sweepAmount, sweepFee: sweepFee)
        case let x where x.contains("Fee is too low / Not sufficient priority"):
            self = .feeTooLow(finalFee: finalFee, sweepAmount: sweepAmount, sweepFee: sweepFee)
        default:
            Logger.shared.error("BitcoinChainTransactionError failed to map \(stringValue)")
            self = .unknown(finalFee: finalFee, sweepAmount: sweepAmount, sweepFee: sweepFee)
        }
    }
}

public protocol BitcoinChainSendBridgeAPI {
    func sign(with secondPassword: String?) -> Single<EngineTransaction>
    func buildProposal<Token: BitcoinChainToken>(
        with destination: BitcoinChainReceiveAddress<Token>,
        amount: MoneyValue,
        fees: MoneyValue,
        source: CryptoAccount
    ) -> Single<BitcoinChainTransactionProposal<Token>>

    func buildCandidate<Token: BitcoinChainToken>(
        with proposal: BitcoinChainTransactionProposal<Token>
    ) -> Single<BitcoinChainTransactionCandidate<Token>>

    func send(coin: BitcoinChainCoin, with secondPassword: String?) -> Single<String>
}
