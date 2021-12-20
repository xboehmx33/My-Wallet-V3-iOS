// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

extension OpenBanking {

    public enum Error: Swift.Error, Equatable, Hashable {
        case message(String)
        case code(String)
        case state(State.Error)
        case other(Swift.Error)
        case timeout
    }
}

extension OpenBanking.Error: ExpressibleByError, CustomStringConvertible {

    public init<E>(_ error: E) where E: Error {
        switch error {
        case let error as OpenBanking.Error:
            self = error
        case let error as OpenBanking.State.Error:
            self = .state(error)
        case let error:
            self = .other(error)
        }
    }

    public var any: Error {
        switch self {
        case .message, .code, .timeout:
            return self
        case .state(let error):
            return error
        case .other(let error):
            return error
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: any))
    }

    public static func == (lhs: OpenBanking.Error, rhs: OpenBanking.Error) -> Bool {
        String(describing: lhs.any) == String(describing: rhs.any)
    }

    public var description: String {
        switch self {
        case .timeout:
            return "timeout"
        case .message(let description), .code(let description):
            return description
        case .state(let error):
            return String(describing: error)
        case .other(let error):
            switch error {
            case let error as CustomStringConvertible:
                return error.description
            default:
                return "\(error)"
            }
        }
    }

    public var localizedDescription: String { description }
}

extension OpenBanking.Error: Codable {

    public init(from decoder: Decoder) throws {
        self = try .code(String(from: decoder))
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .code(let code):
            try code.encode(to: encoder)
        default:
            throw EncodingError.invalidValue(
                self,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription: "Cannot encode error of type \(String(describing: self))"
                )
            )
        }
    }
}

extension OpenBanking.Error: TimeoutFailure {}
