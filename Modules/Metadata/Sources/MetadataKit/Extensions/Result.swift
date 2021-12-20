// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

extension Result where Failure == Error {

    func castError<E: Error>() -> Result<Success, E> {
        castError(to: E.self)
    }

    func castError<E: Error>(to type: E.Type) -> Result<Success, E> {
        mapError { error in
            error as! E
        }
    }
}

func catchToResult<T, E: Error>(
    castFailureTo: E.Type,
    fn: () throws -> T
) -> Result<T, E> {
    Result { try fn() }
        .mapError { error in
            error as! E
        }
}

extension Result {

    /// Creates a new result by evaluating a throwing closure, capturing the
    /// returned value as a success, or casting any error to the provided type.
    ///
    /// - Parameters:
    ///   - castFailureTo: the error type to cast the error to. Note this will crash if the thrown error doesn't match the provided type.
    ///   - body: A throwing closure to evaluate.
    /// - Returns: A `Result` of `Success` or `E`
    static func catchToResult<E: Error>(
        castFailureTo: E.Type,
        catching body: () throws -> Success
    ) -> Result<Success, E> {
        MetadataKit.catchToResult(castFailureTo: E.self, fn: body)
    }
}
