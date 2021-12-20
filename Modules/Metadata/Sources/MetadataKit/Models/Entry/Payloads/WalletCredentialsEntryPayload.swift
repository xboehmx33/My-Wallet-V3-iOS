// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct WalletCredentialsEntryPayload: MetadataNodeEntry, Hashable {

    public enum CodingKeys: String, CodingKey {
        case guid
        case password
        case sharedKey
    }

    public static let type: EntryType = .walletCredentials

    public var isValid: Bool {
        !guid.isEmpty && !password.isEmpty && !sharedKey.isEmpty
    }

    public let guid: String
    public let password: String
    public let sharedKey: String

    public init(
        guid: String,
        password: String,
        sharedKey: String
    ) {
        self.guid = guid
        self.password = password
        self.sharedKey = sharedKey
    }
}
