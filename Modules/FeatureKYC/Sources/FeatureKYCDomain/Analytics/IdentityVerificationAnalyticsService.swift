// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import PlatformKit
import ToolKit

final class IdentityVerificationAnalyticsService: IdentityVerificationAnalyticsServiceAPI {

    private typealias Event = AnalyticsEvents.New.Verification

    private let analyticsRecorder: AnalyticsEventRecorderAPI

    init(analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        self.analyticsRecorder = analyticsRecorder
    }

    func recordLocalError() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .localError,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }

    func recordNetworkError() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .networkError,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }

    func recordServerError() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .serverError,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }

    func recordUploadError() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .uploadError,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }

    func recordVideoFailure() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .videoFailed,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }

    func recordUnknownError() {
        analyticsRecorder.record(
            events: [
                Event.verificationSubmissionFailed(
                    failureReason: .unknown,
                    provider: .blockchain,
                    tier: 2
                )
            ]
        )
    }
}
