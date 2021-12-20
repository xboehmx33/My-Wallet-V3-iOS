// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public enum MasterKeyError: Error {
    case unknown
}

public struct MasterKey: Equatable {}

extension MasterKey {

    public static func from(seedHex: String) -> Result<MasterKey, MasterKeyError> {
        .failure(.unknown)
    }
}
