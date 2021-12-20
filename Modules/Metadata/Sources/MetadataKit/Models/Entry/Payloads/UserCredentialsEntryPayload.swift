// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct UserCredentialsEntryPayload: MetadataNodeEntry, Hashable {

    public enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lifetimeToken = "lifetime_token"
    }

    public static let type: EntryType = .userCredentials

    public var isValid: Bool {
        !userId.isEmpty && !lifetimeToken.isEmpty
    }

    public let userId: String
    public let lifetimeToken: String

    public init(
        userId: String,
        lifetimeToken: String
    ) {
        self.userId = userId
        self.lifetimeToken = lifetimeToken
    }
}
