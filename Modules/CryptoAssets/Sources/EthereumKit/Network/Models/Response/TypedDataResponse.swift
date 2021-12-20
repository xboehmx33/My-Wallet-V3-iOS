// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

struct TypedDataPayload: Decodable {
    let message: [String: Item]
}

extension TypedDataPayload {
    enum Item: Decodable, CustomStringConvertible {
        case dictionary([String: Item])
        case array([Item])
        case bool(Bool)
        case null
        case number(Float)
        case string(String)

        var description: String {
            switch self {
            case .array(let value):
                return value.description
            case .bool(let value):
                return value.description
            case .dictionary(let value):
                return value.description
            case .null:
                return "null"
            case .number(let value):
                return value.description
            case .string(let value):
                return "\"\(value)\""
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let value = try? container.decode([String: Item].self) {
                self = .dictionary(value)
            } else if let value = try? container.decode([Item].self) {
                self = .array(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? container.decode(Float.self) {
                self = .number(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                throw DecodingError.typeMismatch(
                    Item.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Item is not of a known type."
                    )
                )
            }
        }
    }
}
