// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public protocol OptionalProtocol: ExpressibleByNilLiteral {
    associatedtype Wrapped

    var wrapped: Wrapped? { get }
    static var none: Self { get }

    static func some(_ newValue: Wrapped) -> Self
    func map<U>(_ f: (Wrapped) throws -> U) rethrows -> U?
    func flatMap<U>(_ f: (Wrapped) throws -> U?) rethrows -> U?
}

extension Optional: OptionalProtocol {
    public var wrapped: Wrapped? { self }
}

extension Optional {

    @discardableResult
    public func or<E>(throw error: @autoclosure () -> E) throws -> Wrapped where E: Error {
        guard let value = self else { throw error() }
        return value
    }

    public func or(default defaultValue: @autoclosure () -> Wrapped) -> Wrapped {
        guard let value = self else { return defaultValue() }
        return value
    }
}

// Optional Assignment
infix operator ?=: AssignmentPrecedence

public func ?= <A>(l: inout A, r: A?) {
    if let r = r { l = r }
}
