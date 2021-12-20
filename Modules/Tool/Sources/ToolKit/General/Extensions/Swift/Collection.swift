// Copyright © Blockchain Luxembourg S.A. All rights reserved.

extension Collection {

    public func filter<T>(_ type: T.Type) -> [T] {
        compactMap { $0 as? T }
    }
}
