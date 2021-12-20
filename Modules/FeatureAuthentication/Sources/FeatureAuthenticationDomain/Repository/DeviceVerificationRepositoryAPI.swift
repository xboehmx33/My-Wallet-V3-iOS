// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

/// `DeviceVerificationRepositoryAPI` is the interface for communicating with the AuthenticationAPIClient for various data layer operations
public protocol DeviceVerificationRepositoryAPI {

    /// Sends a verification email to the user's email address. Thie will trigger the send GUID reminder endpoint and user will receive a link to verify their device in their inbox if they have an account registered with the email
    /// - Parameters: sessionToken: The session token stored in the repository
    /// - Parameters: emailAddress: The email address of the user
    /// - Parameters: captcha: The captcha token returned from reCaptcha Service
    /// - Returns: A combine `Publisher` that emits Void on success or DeviceVerificationServiceError on failure
    func sendDeviceVerificationEmail(
        sessionToken: String,
        to emailAddress: String,
        captcha: String
    ) -> AnyPublisher<Void, DeviceVerificationServiceError>

    /// Authorize the login to the associated email identified by the email code. The email code is received by decrypting the base64 information encrypted in the magic link from the device verification email
    /// - Parameters: sessionToken: The session token stored in the repository
    /// - Parameters: emailCode: The email code for the authorization
    /// - Returns: A combine `Publisher` that emits Void on success or DeviceVerificationServiceError on failure
    func authorizeLogin(
        sessionToken: String,
        emailCode: String
    ) -> AnyPublisher<Void, DeviceVerificationServiceError>

    /// Attempting to poll for wallet information until the backend return the desired response
    /// - Parameters: sessionToken: The session token stored in the repository
    /// - Returns: A combine `Publisher` that emits `Result<WalletInfo, WalletInfoPollingError>` or DeviceVerificationServiceError on failure
    func pollForWalletInfo(
        sessionToken: String
    ) -> AnyPublisher<Result<WalletInfo, WalletInfoPollingError>, DeviceVerificationServiceError>

    /// Authorize device verification from a login request generated from another device
    /// - Parameters: sessionToken: sessionToken from the another device's request
    /// - Parameters: payload: the base64 encoded wallet info from the another device's request
    /// - Parameters: confirmDevice: whether to confirm device or not, if nil, will trigger confirmation required error
    /// - Returns: A combine `Publisher` that emits `Void` or `AuthorizeVerifyDeviceError` if failed
    func authorizeVerifyDevice(
        from sessionToken: String,
        payload: String,
        confirmDevice: Bool?
    ) -> AnyPublisher<Void, AuthorizeVerifyDeviceError>
}
