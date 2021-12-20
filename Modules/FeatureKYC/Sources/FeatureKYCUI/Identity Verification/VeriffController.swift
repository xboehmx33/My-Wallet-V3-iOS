// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import PlatformKit
import UIKit
import Veriff

protocol VeriffController: UIViewController, VeriffSdkDelegate {

    var veriff: VeriffSdk { get }

    // Actions

    func veriffCredentialsRequest()

    func launchVeriffController(credentials: VeriffCredentials)

    // Completion handlers

    func onVeriffSubmissionCompleted()

    func trackInternalVeriffError(_ error: InternalVeriffError)

    func onVeriffError(message: String)

    func onVeriffCancelled()
}

extension VeriffController where Self: UIViewController {

    internal var veriff: VeriffSdk {
        VeriffSdk.shared
    }

    func launchVeriffController(credentials: VeriffCredentials) {
        veriff.delegate = self
        veriff.startAuthentication(sessionUrl: credentials.url)
    }
}

enum InternalVeriffError: Swift.Error {
    case cameraUnavailable
    case microphoneUnavailable
    case serverError
    case localError
    case networkError
    case uploadError
    case videoFailed
    case deprecatedSDKVersion
    case unknown

    init(veriffError: VeriffSdk.Error) {
        switch veriffError {
        case .cameraUnavailable:
            self = .cameraUnavailable
        case .microphoneUnavailable:
            self = .microphoneUnavailable
        case .serverError:
            self = .serverError
        case .localError:
            self = .localError
        case .networkError:
            self = .networkError
        case .uploadError:
            self = .uploadError
        case .videoFailed:
            self = .videoFailed
        case .deprecatedSDKVersion:
            self = .deprecatedSDKVersion
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

extension VeriffSdk.Error {
    var localizedErrorMessage: String {
        switch self {
        case .cameraUnavailable:
            return LocalizationConstants.Errors.cameraAccessDeniedMessage
        case .microphoneUnavailable:
            return LocalizationConstants.Errors.microphoneAccessDeniedMessage
        case .deprecatedSDKVersion,
             .localError,
             .networkError,
             .serverError,
             .unknown,
             .uploadError,
             .videoFailed:
            return LocalizationConstants.Errors.genericError
        @unknown default:
            return LocalizationConstants.Errors.genericError
        }
    }
}
