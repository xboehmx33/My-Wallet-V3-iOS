// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct Credentials {

    let guid: String
    let sharedKey: String
    let password: String

    public init(
        guid: String,
        sharedKey: String,
        password: String
    ) {
        self.guid = guid
        self.sharedKey = sharedKey
        self.password = password
    }
}
