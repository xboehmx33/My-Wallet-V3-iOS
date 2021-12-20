// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public enum MetadataSaveError: FromEncodingError {
    case encodingError(EncodingError)

    public static func from(_ encodingError: EncodingError) -> Self {
        .encodingError(encodingError)
    }
}
