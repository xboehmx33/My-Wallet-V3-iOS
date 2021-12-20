// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import NetworkKit
import PlatformKit
import RxSwift

/// Remote notification network service
final class RemoteNotificationNetworkService {

    // MARK: - Types

    enum PushNotificationError: Error {
        case registrationFailure
        case missingCredentials
        case emptyCredentials
        case couldNotBuildRequestBody
    }

    private struct RegistrationResponseData: Decodable {
        let success: Bool
    }

    // MARK: - Properties

    private let url: String
    private let networkAdapter: NetworkAdapterAPI

    // MARK: - Setup

    init(
        url: String = BlockchainAPI.shared.pushNotificationsUrl,
        networkAdapter: NetworkAdapterAPI = resolve()
    ) {
        self.url = url
        self.networkAdapter = networkAdapter
    }
}

// MARK: - RemoteNotificationNetworkServicing

extension RemoteNotificationNetworkService: RemoteNotificationNetworkServicing {

    func register(
        with token: String,
        sharedKeyProvider: SharedKeyRepositoryAPI,
        guidProvider: GuidRepositoryAPI
    ) -> Single<Void> {

        func performRequest(
            request: NetworkRequest
        ) -> AnyPublisher<RegistrationResponseData, NetworkError> {
            networkAdapter.perform(request: request)
        }

        return registrationRequest(with: token, sharedKeyProvider: sharedKeyProvider, guidProvider: guidProvider)
            .flatMap(weak: self) { _, request -> Single<RegistrationResponseData> in
                performRequest(request: request)
                    .asSingle()
            }
            .map { response -> Void in
                guard response.success
                else { throw PushNotificationError.registrationFailure }
                return ()
            }
    }

    private func registrationRequest(
        with token: String,
        sharedKeyProvider: SharedKeyRepositoryAPI,
        guidProvider: GuidRepositoryAPI
    ) -> Single<NetworkRequest> {
        Single
            .zip(
                sharedKeyProvider.sharedKey.asSingle(),
                guidProvider.guid.asSingle()
            )
            .map { credentials -> RemoteNotificationTokenQueryParametersBuilder in
                guard let guid: String = credentials.1,
                      let sharedKey: String = credentials.0
                else {
                    throw PushNotificationError.missingCredentials
                }
                guard !guid.isEmpty, !sharedKey.isEmpty else {
                    throw PushNotificationError.emptyCredentials
                }
                let builder = try RemoteNotificationTokenQueryParametersBuilder(
                    guid: guid,
                    sharedKey: sharedKey,
                    token: token
                )
                return builder
            }
            .map { builder -> Data in
                guard let parameters = builder.parameters else {
                    throw PushNotificationError.couldNotBuildRequestBody
                }
                return parameters
            }
            .map(weak: self) { (self, body) -> NetworkRequest in
                let url = URL(string: self.url)!
                return NetworkRequest(
                    endpoint: url,
                    method: .post,
                    body: body,
                    contentType: .formUrlEncoded
                )
            }
    }
}
