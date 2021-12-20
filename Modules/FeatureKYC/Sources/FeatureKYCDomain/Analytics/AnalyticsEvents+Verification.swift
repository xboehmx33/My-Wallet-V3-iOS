// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import PlatformKit
import ToolKit

extension AnalyticsEvents.New {
    public enum Verification: AnalyticsEvent {

        public var type: AnalyticsEventType { .nabu }

        case verificationSubmissionFailed(
            failureReason: FailureReason,
            provider: Provider,
            tier: Int
        )
    }

    public enum FailureReason: String, StringRawRepresentable {
        case localError = "LOCAL_ERROR"
        case networkError = "NETWORK_ERROR"
        case serverError = "SERVER_ERROR"
        case uploadError = "UPLOAD_ERROR"
        case videoFailed = "VIDEO_FAILED"
        case unknown = "UNKNOWN"
    }

    public enum Provider: String, StringRawRepresentable {
        case blockchain = "BLOCKCHAIN"
        case manual = "MANUAL"
        case onfido = "ONFIDO"
        case rdc = "RDC"
        case rdcMedia = "RDC_MEDIA"
        case rdcPep = "RDC_PEP"
        case veriff = "VERIFF"
    }
}
