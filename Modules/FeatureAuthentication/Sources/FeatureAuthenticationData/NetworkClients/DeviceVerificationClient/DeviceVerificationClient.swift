// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import Foundation
import NetworkKit
import ToolKit

final class DeviceVerificationClient: DeviceVerificationClientAPI {

    // MARK: - Types

    private enum Path {
        static let wallet = ["wallet"]
        static let emailReminder = ["auth", "email-reminder"]
        static let pollWalletInfo = ["wallet", "poll-for-wallet-info"]
    }

    private enum Parameters {
        enum AuthorizeApprove {
            static let method = "method"
            static let comfirmApproval = "confirm_approval"
            static let token = "token"
        }

        enum AuthorizeVerifyDevice {
            static let method = "method"
            static let fromSessionId = "fromSessionId"
            static let payload = "payload"
            static let confirmDevice = "confirm_device"
        }
    }

    private enum HeaderKey: String {
        case cookie
    }

    // MARK: - Properties

    private let walletRequestBuilder: RequestBuilder
    private let defaultRequestBuilder: RequestBuilder
    private let networkAdapter: NetworkAdapterAPI

    // MARK: - Setup

    init(
        networkAdapter: NetworkAdapterAPI = resolve(),
        walletRequestBuilder: RequestBuilder = resolve(tag: DIKitContext.wallet),
        defaultRequestBuilder: RequestBuilder = resolve()
    ) {
        self.networkAdapter = networkAdapter
        self.walletRequestBuilder = walletRequestBuilder
        self.defaultRequestBuilder = defaultRequestBuilder
    }

    // MARK: - Methods

    func sendGuidReminder(
        sessionToken: String,
        emailAddress: String,
        captcha: String
    ) -> AnyPublisher<Void, NetworkError> {
        struct Payload: Encodable {
            let email: String
            let captcha: String
            let siteKey: String
            let product: String
        }
        let headers = [HttpHeaderField.authorization: "Bearer \(sessionToken)"]
        let payload = Payload(
            email: emailAddress,
            captcha: captcha,
            siteKey: AuthenticationKeys.googleRecaptchaSiteKey,
            product: "WALLET"
        )
        let request = defaultRequestBuilder.post(
            path: Path.emailReminder,
            body: try? payload.encode(),
            headers: headers
        )!
        return networkAdapter.perform(request: request)
    }

    func authorizeApprove(
        sessionToken: String,
        emailCode: String
    ) -> AnyPublisher<AuthorizeApproveResponse, NetworkError> {
        let headers = [HeaderKey.cookie.rawValue: "SID=\(sessionToken)"]
        let parameters = [
            URLQueryItem(
                name: Parameters.AuthorizeApprove.method,
                value: "authorize-approve"
            ),
            URLQueryItem(
                name: Parameters.AuthorizeApprove.comfirmApproval,
                value: "true"
            ),
            URLQueryItem(
                name: Parameters.AuthorizeApprove.token,
                value: emailCode
            )
        ]
        let data = RequestBuilder.body(from: parameters)
        let request = walletRequestBuilder.post(
            path: Path.wallet,
            body: data,
            headers: headers,
            contentType: .formUrlEncoded
        )!
        return networkAdapter.perform(request: request)
            .catch { networkError -> AnyPublisher<AuthorizeApproveResponse, NetworkError> in
                // this request can send a specific `409` status code which we need to capture
                // and not throw an error causing the stream to end...
                guard case .rawServerError(let value) = networkError else {
                    return .failure(networkError)
                }
                guard value.response.statusCode == 409,
                      let payload = value.payload
                else {
                    return .failure(networkError)
                }
                guard let value = try? payload.decode(to: AuthorizeApproveResponse.self) else {
                    return .failure(networkError)
                }
                return .just(value)
            }
            .eraseToAnyPublisher()
    }

    func pollForWalletInfo(
        sessionToken: String
    ) -> AnyPublisher<WalletInfoPollResultResponse, NetworkError> {

        func decodeType(
            response: RawServerResponse
        ) -> AnyPublisher<WalletInfoPollResponse.ResponseType, NetworkError> {
            Just(Result { try Data(response.data.utf8).decode(to: WalletInfoPollResponse.self).responseType })
                .setFailureType(to: NetworkError.self)
                .flatMap { result -> AnyPublisher<WalletInfoPollResponse.ResponseType, NetworkError> in
                    switch result {
                    case .success(let type):
                        return .just(type)
                    case .failure(let error):
                        return .failure(NetworkError.payloadError(.badData(rawPayload: error.localizedDescription)))
                    }
                }
                .eraseToAnyPublisher()
        }

        func decodePayload(
            responseType: WalletInfoPollResponse.ResponseType,
            response: RawServerResponse
        ) -> AnyPublisher<WalletInfoPollResultResponse, NetworkError> {
            switch responseType {
            case .walletInfo:
                return Just(Result { try Data(response.data.utf8).decode(to: WalletInfo.self) })
                    .setFailureType(to: NetworkError.self)
                    .flatMap { result -> AnyPublisher<WalletInfoPollResultResponse, NetworkError> in
                        switch result {
                        case .success(let walletInfo):
                            return .just(.walletInfo(walletInfo))
                        case .failure(let error):
                            return .failure(NetworkError.payloadError(.badData(rawPayload: error.localizedDescription)))
                        }
                    }
                    .eraseToAnyPublisher()
            case .continuePolling:
                return .just(.continuePolling)
            case .requestDenied:
                return .just(.requestDenied)
            }
        }

        let headers = [HttpHeaderField.authorization: "Bearer \(sessionToken)"]
        let request = walletRequestBuilder.get(
            path: Path.pollWalletInfo,
            headers: headers
        )!
        return networkAdapter.perform(request: request)
            .flatMap { response -> AnyPublisher<WalletInfoPollResultResponse, NetworkError> in
                decodeType(response: response)
                    .flatMap { type -> AnyPublisher<WalletInfoPollResultResponse, NetworkError> in
                        decodePayload(responseType: type, response: response)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func authorizeVerifyDevice(
        from sessionToken: String,
        payload: String,
        confirmDevice: Bool?
    ) -> AnyPublisher<Void, NetworkError> {
        var parameters = [
            URLQueryItem(
                name: Parameters.AuthorizeVerifyDevice.method,
                value: "authorize-verify-device"
            ),
            URLQueryItem(
                name: Parameters.AuthorizeVerifyDevice.fromSessionId,
                value: sessionToken
            ),
            URLQueryItem(
                name: Parameters.AuthorizeVerifyDevice.payload,
                value: payload
            )
        ]
        if let confirm = confirmDevice {
            parameters.append(
                URLQueryItem(
                    name: Parameters.AuthorizeVerifyDevice.confirmDevice,
                    value: String(confirm)
                )
            )
        }
        let data = RequestBuilder.body(from: parameters)
        let request = walletRequestBuilder.post(
            path: Path.wallet,
            body: data,
            contentType: .formUrlEncoded
        )!
        return networkAdapter.perform(request: request)
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
