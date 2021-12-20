// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import FeatureAuthenticationData
@testable import FeatureAuthenticationDomain
import TestKit
import XCTest

@testable import FeatureAuthenticationMock

final class JWTServiceTests: XCTestCase {

    private var subject: JWTService!
    private var jwtRepository: JWTRepositoryMock!
    private var walletRepository: MockWalletRepository!

    override func setUp() {
        super.setUp()

        jwtRepository = JWTRepositoryMock()
        walletRepository = MockWalletRepository()
        subject = JWTService(
            jwtRepository: jwtRepository,
            credentialsRepository: walletRepository
        )
    }

    override func tearDown() {
        jwtRepository = nil
        walletRepository = nil
        subject = nil
        super.tearDown()
    }

    func testSuccessfulTokenFetch() throws {

        // Arrange
        jwtRepository.expectedResult = .success("jwt-token")

        let offlineToken = NabuOfflineToken(
            userId: "user-id",
            token: "offline-token"
        )

        let offlineTokenSetPublisher = walletRepository.set(offlineToken: offlineToken)
        let guidSetPublisher = walletRepository.set(guid: "guid")
        let sharedKeySetPublisher = walletRepository.set(sharedKey: "shared-key")
        XCTAssertPublisherCompletion([guidSetPublisher, sharedKeySetPublisher])
        XCTAssertPublisherCompletion(offlineTokenSetPublisher)

        // Act
        XCTAssertPublisherValues(subject.token, "jwt-token", timeout: 5.0)
    }

    func testFailureForMissingCredentials() throws {

        // Arrange
        jwtRepository.expectedResult = .success("jwt-token")

        let offlineToken = NabuOfflineToken(
            userId: "user-id",
            token: "offline-token",
            created: nil
        )

        let offlineTokenSetPublisher = walletRepository.set(offlineToken: offlineToken)
        let sharedKeySetPublisher = walletRepository.set(sharedKey: "shared-key")
        XCTAssertPublisherCompletion(offlineTokenSetPublisher)
        XCTAssertPublisherCompletion(sharedKeySetPublisher)

        // Act
        XCTAssertPublisherError(subject.token, .failedToRetrieveCredentials(.guid), timeout: 5.0)
    }
}
