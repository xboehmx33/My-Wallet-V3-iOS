// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Combine
import DIKit
import Foundation
import NetworkKit
import PlatformKit

protocol LatestBlockClientAPI {
    var latestBlock: AnyPublisher<JsonRpcSingleHexaResponse, NetworkError> { get }
}

protocol EstimateGasClientAPI {
    func estimateGas(
        transaction: EthereumJsonRpcTransaction
    ) -> AnyPublisher<JsonRpcSingleHexaResponse, NetworkError>
}

final class RPCClient: LatestBlockClientAPI, EstimateGasClientAPI {

    private enum Endpoint {
        static let rpcNode: [String] = ["eth", "nodes", "rpc"]
    }

    private enum Method {
        static let eth_blockNumber = "eth_blockNumber"
        static let eth_estimateGas = "eth_estimateGas"
    }

    // MARK: - Properties

    /// Streams the latest block
    var latestBlock: AnyPublisher<JsonRpcSingleHexaResponse, NetworkError> {
        rpcRequest(encodable: BlockNumberRequest())
            .publisher
            .flatMap { [networkAdapter] networkRequest in
                networkAdapter.perform(request: networkRequest)
            }
            .eraseToAnyPublisher()
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

    func estimateGas(
        transaction: EthereumJsonRpcTransaction
    ) -> AnyPublisher<JsonRpcSingleHexaResponse, NetworkError> {
        rpcRequest(encodable: EstimateGasRequest(transaction: transaction))
            .publisher
            .flatMap { [networkAdapter] networkRequest in
                networkAdapter.perform(request: networkRequest)
            }
            .eraseToAnyPublisher()
    }

    private func rpcRequest(encodable: Encodable) -> Result<NetworkRequest, NetworkError> {
        guard let data = try? encodable.data() else {
            return .failure(.payloadError(.emptyData))
        }
        return requestBuilder.post(
            path: Endpoint.rpcNode,
            body: data
        )
        .flatMap { .success($0) }
        ?? .failure(.payloadError(.emptyData))
    }
}
