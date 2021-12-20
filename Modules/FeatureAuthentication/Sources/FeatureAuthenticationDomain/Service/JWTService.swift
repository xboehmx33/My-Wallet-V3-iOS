// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import NetworkError
import ToolKit

public enum JWTServiceError: Error, Equatable {
    case failedToRetrieveCredentials(MissingCredentialsError)
    case failedToRetrieveJWTToken
    case networkError(NetworkError)
}

public protocol JWTServiceAPI: AnyObject {
    /// Retrieves the JWT with the guid and sharedKey cached in `CredentialsRepository`
    var token: AnyPublisher<String, JWTServiceError> { get }

    /// Retrieves the JWT with guid and sharedKey (to be provided)
    /// - Parameters:
    ///   - guid: the wallet GUID
    ///   - sharedKey: the wallet sharedKey
    func fetchToken(
        guid: String,
        sharedKey: String
    ) -> AnyPublisher<String, JWTServiceError>
}

final class JWTService: JWTServiceAPI {

    // MARK: - Properties

    var token: AnyPublisher<String, JWTServiceError> {
        let jwtRepository = jwtRepository
        return credentialsRepository
            .credentials
            .mapError(JWTServiceError.failedToRetrieveCredentials)
            .flatMap { [jwtRepository] guid, sharedKey -> AnyPublisher<String, JWTServiceError> in
                jwtRepository
                    .requestJWT(guid: guid, sharedKey: sharedKey)
            }
            .eraseToAnyPublisher()
    }

    private let jwtRepository: JWTRepositoryAPI
    private let credentialsRepository: CredentialsRepositoryAPI

    // MARK: - Setup

    init(
        jwtRepository: JWTRepositoryAPI = resolve(),
        credentialsRepository: CredentialsRepositoryAPI = resolve()
    ) {
        self.jwtRepository = jwtRepository
        self.credentialsRepository = credentialsRepository
    }

    // MARK: - API

    func fetchToken(
        guid: String,
        sharedKey: String
    ) -> AnyPublisher<String, JWTServiceError> {
        jwtRepository.requestJWT(guid: guid, sharedKey: sharedKey)
    }
}
