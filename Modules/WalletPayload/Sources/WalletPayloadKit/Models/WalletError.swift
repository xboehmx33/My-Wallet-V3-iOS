// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization

public enum WalletError: LocalizedError, Equatable {
    case payloadNotFound
    case initialization(WalletInitializationError)
    case decryption(WalletDecryptionError)

    public var errorDescription: String? {
        switch self {
        case .payloadNotFound:
            // TODO: Add Localization
            return "We could't find wallet data to decrypt"
        case .decryption(let error):
            return error.errorDescription
        case .initialization(let error):
            return error.errorDescription
        }
    }
}

public enum WalletInitializationError: LocalizedError, Equatable {
    case unknown
    case missingSeedHex
    case metadataInitialization
    case needsSecondPassword

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return ""
        case .missingSeedHex:
            return ""
        case .metadataInitialization:
            return ""
        case .needsSecondPassword:
            return ""
        }
    }
}

public enum WalletDecryptionError: LocalizedError, Equatable {
    case decryptionError
    case decodeError(Error)

    public var errorDescription: String? {
        switch self {
        case .decryptionError:
            return LocalizationConstants.WalletPayloadKit.Error.decryptionFailed
        case .decodeError(let error):
            return error.localizedDescription
        }
    }

    public static func == (lhs: WalletDecryptionError, rhs: WalletDecryptionError) -> Bool {
        switch (lhs, rhs) {
        case (.decryptionError, decryptionError):
            return true
        case (.decodeError(let lhsError), .decodeError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
