// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension Data {

    static func from(utf8string: String) -> Self {
        Self(utf8string.utf8)
    }
}
