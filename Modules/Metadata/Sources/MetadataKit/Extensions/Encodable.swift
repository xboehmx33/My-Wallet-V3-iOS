// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension Encodable {

    /// Encodes the value to a JSON string
    /// - Returns: the JSON string
    func encodeToJSONString() -> Result<String, EncodingError> {
        JSONEncoder().encode(value: self)
            .map(String.decodeFromUTF8(codeUnits:))
    }
}
