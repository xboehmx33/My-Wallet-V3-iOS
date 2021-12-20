// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NetworkError

/// Potential errors that may arise during 2FA initialization
public enum TwoFAWalletServiceError: Error, Equatable {

    /// The payload returned from the backend is empty
    case missingPayload

    /// Cannot send 2FA because credentials are missing
    case missingCredentials(MissingCredentialsError)

    /// Cannot send 2FA code because the code is empty
    case missingCode

    /// 2FA OTP code is wrong
    case wrongCode(attemptsLeft: Int)

    /// Account is locked
    case accountLocked

    /// Network related errors
    case networkError(NetworkError)
}

public protocol TwoFAWalletServiceAPI: AnyObject {
    func send(code: String) -> AnyPublisher<Void, TwoFAWalletServiceError>
}
