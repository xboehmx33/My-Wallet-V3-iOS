// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public protocol FromDecodingError: Error {

    static func from(_ decodingError: DecodingError) -> Self
}
