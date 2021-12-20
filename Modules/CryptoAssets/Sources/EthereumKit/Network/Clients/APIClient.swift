// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NetworkKit
import PlatformKit

protocol TransactionPushClientAPI: AnyObject {

    func push(
        transaction: EthereumTransactionEncoded
    ) -> AnyPublisher<EthereumPushTxResponse, NetworkError>
}

protocol TransactionClientAPI {

    func transaction(
        with hash: String
    ) -> AnyPublisher<EthereumHistoricalTransactionResponse, NetworkError>

    func transactions(
        for account: String
    ) -> AnyPublisher<[EthereumHistoricalTransactionResponse], NetworkError>
}

protocol BalanceClientAPI {

    func balanceDetails(
        from address: String
    ) -> AnyPublisher<BalanceDetailsResponse, ClientError>
}

protocol TransactionFeeClientAPI {

    func fees(
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError>
}

/// Potential errors
enum ClientError: Error {

    /// A `Network` layer error
    case networkError(NetworkError)

    /// Balance is missing for address
    case missingBalanceResponseForAddress

    /// Account is missing for
    case missingAccountResponseForAddress
}

protocol EthereumAccountClientAPI {

    /// Checks if a given ethereum address is associated with an ethereum contract.
    ///
    /// - Parameter address: The ethereum address to check.
    ///
    /// - Returns: A publisher that emits a `EthereumIsContractResponse` on success, or a `NetworkError` on failure.
    func isContract(address: String) -> AnyPublisher<EthereumIsContractResponse, NetworkError>
}

final class APIClient: TransactionPushClientAPI,
    TransactionClientAPI,
    BalanceClientAPI,
    TransactionFeeClientAPI,
    EthereumAccountClientAPI
{

    // MARK: - Types

    /// Privately used endpoint data
    private enum Endpoint {
        static let fees: [String] = ["mempool", "fees", "eth"]
        static let base: [String] = ["eth"]
        static let pushTx: [String] = base + ["pushtx"]

        static func balance(for address: String) -> [String] {
            base + ["account", address, "balance"]
        }

        static func isContract(address: String) -> [String] {
            base + ["account", address, "isContract"]
        }
    }

    /// Privately used endpoint data
    private enum EndpointV2 {
        private static let base: [String] = ["v2", "eth", "data"]

        static let latestBlock: [String] = base + ["block", "latest", "number"]

        static func transactions(for address: String) -> [String] {
            base + ["account", address, "transactions"]
        }

        static func transaction(with hash: String) -> [String] {
            base + ["transaction", hash]
        }
    }

    // MARK: - Private Properties

    private let networkAdapter: NetworkAdapterAPI
    private let requestBuilder: RequestBuilder
    private let apiCode: String

    // MARK: - Setup

    init(
        networkAdapter: NetworkAdapterAPI = resolve(),
        requestBuilder: RequestBuilder = resolve(),
        apiCode: APICode = resolve()
    ) {
        self.networkAdapter = networkAdapter
        self.requestBuilder = requestBuilder
        self.apiCode = apiCode
    }

    func fees(
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError> {
        guard cryptoCurrency == .coin(.ethereum) || cryptoCurrency.isERC20 else {
            fatalError("Using Ethereum APIClient for incompatible CryptoCurrency")
        }
        var parameters: [URLQueryItem] = []
        if let contractAddress = cryptoCurrency.erc20ContractAddress {
            parameters.append(URLQueryItem(name: "contractAddress", value: contractAddress))
        }
        let request = requestBuilder.get(
            path: Endpoint.fees,
            parameters: parameters
        )!
        return networkAdapter.perform(request: request)
    }

    /// Pushes a transaction
    func push(
        transaction: EthereumTransactionEncoded
    ) -> AnyPublisher<EthereumPushTxResponse, NetworkError> {
        let pushTxRequest = PushTxRequest(
            rawTx: transaction.rawTransaction,
            api_code: apiCode
        )
        let data = try? JSONEncoder().encode(pushTxRequest)
        let request = requestBuilder.post(
            path: Endpoint.pushTx,
            body: data,
            recordErrors: true
        )!
        return networkAdapter.perform(request: request)
    }

    func transaction(
        with hash: String
    ) -> AnyPublisher<EthereumHistoricalTransactionResponse, NetworkError> {
        let path = EndpointV2.transaction(with: hash)
        let request = requestBuilder.get(path: path)!
        return networkAdapter.perform(request: request)
    }

    /// Fetches transactions for an address - returns an array of transactions
    func transactions(
        for account: String
    ) -> AnyPublisher<[EthereumHistoricalTransactionResponse], NetworkError> {
        let path = EndpointV2.transactions(for: account)
        let request = requestBuilder.get(path: path)!
        return networkAdapter
            .perform(
                request: request,
                responseType: EthereumAccountTransactionsResponse.self
            )
            .map(\.transactions)
            .eraseToAnyPublisher()
    }

    /// Fetches the balance for an address
    func balanceDetails(
        from address: String
    ) -> AnyPublisher<BalanceDetailsResponse, ClientError> {
        let path = Endpoint.balance(for: address)
        let request = requestBuilder.get(path: path)!
        return networkAdapter.perform(request: request)
            .mapError(ClientError.networkError)
            .flatMap { (payload: [String: BalanceDetailsResponse])
                -> AnyPublisher<BalanceDetailsResponse, ClientError> in
                guard let details = payload[address] else {
                    return .failure(.missingBalanceResponseForAddress)
                }
                return .just(details)
            }
            .eraseToAnyPublisher()
    }

    func isContract(address: String) -> AnyPublisher<EthereumIsContractResponse, NetworkError> {
        let path = Endpoint.isContract(address: address)
        let request = requestBuilder.get(path: path)!
        return networkAdapter.perform(request: request)
    }
}

extension CryptoCurrency {
    fileprivate var erc20ContractAddress: String? {
        switch self {
        case .erc20(let model):
            switch model.kind {
            case .erc20(let contractAddress):
                return contractAddress
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
