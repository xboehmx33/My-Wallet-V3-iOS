// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation

/// A Json RPC response with a single hexadecimal number.
struct JsonRpcSingleHexaResponse: Decodable {

    // MARK: Types

    private enum CodingKeys: CodingKey {
        case result
    }

    // MARK: Properties

    let result: BigInt

    // MARK: Init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .result)
        guard let result = BigInt(value.withoutHex, radix: 16) else {
            throw DecodingError.dataCorruptedError(
                forKey: .result,
                in: container,
                debugDescription: "'result' is not a hexadecimal number."
            )
        }
        self.result = result
    }
}
