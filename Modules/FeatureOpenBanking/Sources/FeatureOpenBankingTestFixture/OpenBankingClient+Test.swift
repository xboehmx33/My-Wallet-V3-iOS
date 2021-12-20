// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
@testable import FeatureOpenBankingData
@testable import FeatureOpenBankingDomain
import Foundation
@testable import NetworkKit

extension OpenBanking {

    public static func test<S: Scheduler>(
        requests: [URLRequest: Data] = [:],
        using scheduler: S
    ) -> (banking: OpenBanking, network: ReplayNetworkCommunicator) where
        S.SchedulerTimeType == DispatchQueue.SchedulerTimeType,
        S.SchedulerOptions == DispatchQueue.SchedulerOptions
    {
        let (banking, network) = OpenBankingClient.test(using: scheduler)
        return (
            OpenBanking(banking: banking),
            network
        )
    }
}

extension OpenBankingClient {

    public static func test(_ requests: [URLRequest: Data] = [:]) -> (
        banking: OpenBankingClient,
        communicator: ReplayNetworkCommunicator
    ) {
        test(requests, using: DispatchQueue.immediate)
    }

    public static func test<S: Scheduler>(
        _ requests: [URLRequest: Data] = [:],
        using scheduler: S
    ) -> (
        banking: OpenBankingClient,
        communicator: ReplayNetworkCommunicator
    ) where
        S.SchedulerTimeType == DispatchQueue.SchedulerTimeType,
        S.SchedulerOptions == DispatchQueue.SchedulerOptions
    {
        let communicator = ReplayNetworkCommunicator(requests, in: Bundle.module)
        return (
            OpenBankingClient(
                requestBuilder: RequestBuilder(
                    config: Network.Config(
                        scheme: "https",
                        host: "api.blockchain.info",
                        components: ["nabu-gateway"]
                    ),
                    headers: [
                        "Authorization": "Bearer Token"
                    ]
                ),
                network: NetworkAdapter(
                    communicator: communicator
                ).network,
                scheduler: scheduler.eraseToAnyScheduler(),
                state: .init([.currency: "GBP"])
            ),
            communicator
        )
    }
}

extension Array where Element == NetworkRequest {

    public subscript(method: NetworkRequest.NetworkMethod, url: URL) -> NetworkRequest? {
        first(where: { $0.method == method && $0.urlRequest.url == url })
    }
}

extension URLRequest {

    public init(_ method: NetworkRequest.NetworkMethod, _ url: URL, _ contentType: NetworkRequest.ContentType = .json) {
        self.init(url: url)
        httpMethod = method.rawValue
        addValue(contentType.rawValue, forHTTPHeaderField: "Accept")
    }
}
