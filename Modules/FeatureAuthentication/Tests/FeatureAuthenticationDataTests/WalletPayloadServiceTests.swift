// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
@testable import FeatureAuthenticationData
@testable import FeatureAuthenticationDomain
@testable import FeatureAuthenticationMock
import TestKit
import ToolKit
@testable import WalletPayloadKit
import XCTest

class WalletPayloadServiceTests: XCTestCase {

    /// Tests a valid response to payload fetching that requires 2FA code
    func testValid2FAResponse() throws {
        let expectedAuthType = WalletAuthenticatorType.sms // expect SMS
        let serverResponse = WalletPayloadClient.Response.fake(
            guid: "fake-guid", // expect this fake GUID value
            authenticatorType: expectedAuthType,
            payload: nil
        )
        let repository = MockWalletRepository()

        let sessionTokenSetPublisher = repository.set(sessionToken: "1234-abcd-5678-efgh")
        let guidSetPublisher = repository.set(guid: "fake-guid")
        XCTAssertPublisherCompletion([sessionTokenSetPublisher, guidSetPublisher])

        let client = MockWalletPayloadClient(result: .success(serverResponse))
        let walletRepo = WalletRepo(initialState: .empty)
        let nativeWalletEnabled = false
        let nativeWalletEnabledUseImpl: NativeWalletEnabledUseImpl<WalletPayloadServiceAPI, WalletPayloadServiceAPI> =
            { old, new -> AnyPublisher<Either<WalletPayloadServiceAPI, WalletPayloadServiceAPI>, Never> in
                guard nativeWalletEnabled else {
                    return .just(Either.left(old))
                }
                return .just(Either.right(new))
            }
        let service = WalletPayloadService(
            client: client,
            repository: repository,
            walletRepo: walletRepo,
            nativeWalletEnabledUse: nativeWalletEnabledUseImpl
        )
        let serviceAuthTypePublisher = service.requestUsingSessionToken()
        XCTAssertPublisherValues(serviceAuthTypePublisher, expectedAuthType, timeout: 5.0)

        let repositoryAuthTypePublisher = repository.authenticatorType
        XCTAssertPublisherValues(repositoryAuthTypePublisher, expectedAuthType, timeout: 5.0)
    }

    func testValidPayloadResponse() throws {
        let expectedAuthType = WalletAuthenticatorType.standard // expect no 2FA
        let serverResponse = WalletPayloadClient.Response.fake(
            guid: "fake-guid", // expect this fake GUID value
            authenticatorType: expectedAuthType,
            payload: "{\"pbkdf2_iterations\":1,\"version\":3,\"payload\":\"payload-for-wallet\"}"
        )
        let repository = MockWalletRepository()

        let sessionTokenSetPublisher = repository.set(sessionToken: "1234-abcd-5678-efgh")
        let guidSetPublisher = repository.set(guid: "fake-guid")
        XCTAssertPublisherCompletion([sessionTokenSetPublisher, guidSetPublisher])

        let client = MockWalletPayloadClient(result: .success(serverResponse))
        let walletRepo = WalletRepo(initialState: .empty)
        let nativeWalletEnabled = false
        let nativeWalletEnabledUseImpl: NativeWalletEnabledUseImpl<WalletPayloadServiceAPI, WalletPayloadServiceAPI> =
            { old, new -> AnyPublisher<Either<WalletPayloadServiceAPI, WalletPayloadServiceAPI>, Never> in
                guard nativeWalletEnabled else {
                    return .just(Either.left(old))
                }
                return .just(Either.right(new))
            }
        let service = WalletPayloadService(
            client: client,
            repository: repository,
            walletRepo: walletRepo,
            nativeWalletEnabledUse: nativeWalletEnabledUseImpl
        )
        let serviceAuthTypePublisher = service.requestUsingSessionToken()
        XCTAssertPublisherValues(serviceAuthTypePublisher, expectedAuthType, timeout: 5.0)

        let repositoryAuthTypePublisher = repository.authenticatorType
        XCTAssertPublisherValues(repositoryAuthTypePublisher, expectedAuthType, timeout: 5.0)
        XCTAssertPublisherValues(repository.payload, repository.expectedPayload, timeout: 5.0)
    }
}
