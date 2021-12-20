// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension JSONDecoder {

    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    func decode<T: Decodable>(
        type: T.Type,
        from data: Data
    ) -> Result<T, DecodingError> {
        catchToResult(castFailureTo: DecodingError.self) {
            try decode(type, from: data)
        }
    }
}
