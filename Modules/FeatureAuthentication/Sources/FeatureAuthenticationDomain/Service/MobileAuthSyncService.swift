// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit

final class MobileAuthSyncService: MobileAuthSyncServiceAPI {

    // MARK: - Properties

    private let mobileAuthSyncRepository: MobileAuthSyncRepositoryAPI
    private let credentialsRepository: CredentialsRepositoryAPI

    // MARK: - Setup

    init(
        mobileAuthSyncRepository: MobileAuthSyncRepositoryAPI = resolve(),
        credentialsRepository: CredentialsRepositoryAPI = resolve()
    ) {
        self.mobileAuthSyncRepository = mobileAuthSyncRepository
        self.credentialsRepository = credentialsRepository
    }

    // MARK: - API

    func updateMobileSetup(
        isMobileSetup: Bool
    ) -> AnyPublisher<Void, MobileAuthSyncServiceError> {
        Publishers.Zip(
            credentialsRepository.guid,
            credentialsRepository.sharedKey
        )
        .flatMap { [mobileAuthSyncRepository] guidOrNil, sharedKeyOrNil -> AnyPublisher<Void, MobileAuthSyncServiceError> in
            guard let guid = guidOrNil else {
                return .failure(.missingCredentials(.guid))
            }
            guard let sharedKey = sharedKeyOrNil else {
                return .failure(.missingCredentials(.sharedKey))
            }
            return mobileAuthSyncRepository
                .updateMobileSetup(guid: guid, sharedKey: sharedKey, isMobileSetup: isMobileSetup)
        }
        .eraseToAnyPublisher()
    }

    func verifyCloudBackup(
        hasCloudBackup: Bool
    ) -> AnyPublisher<Void, MobileAuthSyncServiceError> {
        Publishers.Zip(
            credentialsRepository.guid,
            credentialsRepository.sharedKey
        )
        .flatMap { [mobileAuthSyncRepository] guidOrNil, sharedKeyOrNil -> AnyPublisher<Void, MobileAuthSyncServiceError> in
            guard let guid = guidOrNil else {
                return .failure(.missingCredentials(.guid))
            }
            guard let sharedKey = sharedKeyOrNil else {
                return .failure(.missingCredentials(.sharedKey))
            }
            return mobileAuthSyncRepository
                .verifyCloudBackup(guid: guid, sharedKey: sharedKey, hasCloudBackup: hasCloudBackup)
        }
        .eraseToAnyPublisher()
    }
}
