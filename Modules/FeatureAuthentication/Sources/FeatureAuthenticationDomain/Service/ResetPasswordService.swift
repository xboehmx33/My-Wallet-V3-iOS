// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit

public final class ResetPasswordService: ResetPasswordServiceAPI {

    // MARK: - Properties

    private let passwordRepository: PasswordRepositoryAPI

    // MARK: - Setup

    public init(
        passwordRepository: PasswordRepositoryAPI = resolve()
    ) {
        self.passwordRepository = passwordRepository
    }

    // MARK: - Methods

    public func setNewPassword(newPassword: String) -> AnyPublisher<Void, ResetPasswordServiceError> {
        passwordRepository
            .set(password: newPassword)
            .flatMap { [passwordRepository] _ -> AnyPublisher<Void, ResetPasswordServiceError> in
                passwordRepository
                    .sync()
                    .mapError(ResetPasswordServiceError.passwordRepositoryError)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
