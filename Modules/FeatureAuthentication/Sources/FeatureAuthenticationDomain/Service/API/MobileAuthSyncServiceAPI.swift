// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NetworkError

public enum MobileAuthSyncServiceError: Error {
    case missingCredentials(MissingCredentialsError)
    case networkError(NetworkError)
}

public protocol MobileAuthSyncServiceAPI {
    /// Sends a record to the backend server that the mobile wallet has been setup or not. It is considered successfully setup if the user logs in, and not set when the user forgets the wallet. This is for reporting backend metrics on Grafana.
    /// - Returns: A `Combine.Publisher` that returns Void if successful and `MobileAuthSyncServiceError` if failed.

    func updateMobileSetup(
        isMobileSetup: Bool
    ) -> AnyPublisher<Void, MobileAuthSyncServiceError>

    /// Sends a record to the backend server that the cloud backup has been created or cleared. The backup is created when the user logs in, and cleared when the user forgets the wallet. This is for reporting backend metrics on Grafana.
    /// - Returns: A `Combine.Publisher` that returns Void if successful and `MobileAuthSyncServiceError` if failed.
    func verifyCloudBackup(
        hasCloudBackup: Bool
    ) -> AnyPublisher<Void, MobileAuthSyncServiceError>
}
