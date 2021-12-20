// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import ToolKit

final class MetadataService: MetadataServiceAPI {

    // MARK: - Public methods

    func initialize(
        credentials: Credentials,
        masterKey: MasterKey,
        payloadIsDoubleEncrypted: Bool
    ) -> AnyPublisher<MetadataState, MetadataInitialisationError> {
        .just(MetadataState())
    }

    func fetch(
        type: EntryType,
        state: MetadataState
    ) -> AnyPublisher<String, MetadataFetchError> {
        .just("Metadata Entry Payload")
    }

    func save(
        node jsonPayload: String,
        metadataType: EntryType,
        state: MetadataState
    ) -> AnyPublisher<Void, MetadataSaveError> {
        .just(())
    }
}
