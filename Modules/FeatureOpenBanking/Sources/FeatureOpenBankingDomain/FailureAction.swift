// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CasePaths
import Combine
import ToolKit

public protocol FailureAction {
    static func failure(_ error: OpenBanking.Error) -> Self
}

extension FailureAction {
    public static func failure(_ error: Error) -> Self { failure(.init(error)) }
}

extension Publisher where Output: ResultProtocol {

    @_disfavoredOverload
    public func map<T>(
        _ action: @escaping (Output.Success) -> T
    ) -> Publishers.Map<Self, T> where T: FailureAction {
        map { it -> T in
            switch it.result {
            case .success(let value):
                return action(value)
            case .failure(let error):
                return T.failure(error)
            }
        }
    }

    public func map<T>(
        _ action: CasePath<T, Output.Success>
    ) -> Publishers.Map<Self, T> where T: FailureAction {
        map { it -> T in
            switch it.result {
            case .success(let value):
                return action.embed(value)
            case .failure(let error):
                return T.failure(error)
            }
        }
    }
}
