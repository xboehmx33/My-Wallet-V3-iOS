// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public protocol IdentityVerificationAnalyticsServiceAPI {

    func recordLocalError()
    func recordNetworkError()
    func recordServerError()
    func recordUploadError()
    func recordVideoFailure()
    func recordUnknownError()
}
