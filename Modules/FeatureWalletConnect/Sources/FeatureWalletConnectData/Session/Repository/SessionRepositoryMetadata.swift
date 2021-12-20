// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureWalletConnectDomain
import Foundation

final class SessionRepositoryMetadata: SessionRepositoryAPI {

    private let walletConnectMetadata: WalletConnectMetadataAPI

    init(walletConnectMetadata: WalletConnectMetadataAPI = resolve()) {
        self.walletConnectMetadata = walletConnectMetadata
    }

    func contains(session: WalletConnectSession) -> AnyPublisher<Bool, Never> {
        loadSessions()
            .map { sessions in
                sessions
                    .contains(where: { $0.isEqual(session) })
            }
            .eraseToAnyPublisher()
    }

    func store(session: WalletConnectSession) -> AnyPublisher<Void, Never> {
        retrieve()
            .map { sessions -> [WalletConnectSession] in
                var sessions = sessions
                    .filter { item in
                        !item.isEqual(session)
                    }
                sessions.append(session)
                return sessions
            }
            .flatMap { [store] sessions -> AnyPublisher<Void, Never> in
                store(sessions)
            }
            .eraseToAnyPublisher()
    }

    func remove(session: WalletConnectSession) -> AnyPublisher<Void, Never> {
        retrieve()
            .map { sessions in
                sessions.filter { item in
                    !item.isEqual(session)
                }
            }
            .flatMap { [store] sessions -> AnyPublisher<Void, Never> in
                store(sessions)
            }
            .eraseToAnyPublisher()
    }

    func removeAll() -> AnyPublisher<Void, Never> {
        store(sessions: [])
    }

    func retrieve() -> AnyPublisher<[WalletConnectSession], Never> {
        loadSessions()
            .eraseToAnyPublisher()
    }

    private func loadSessions() -> AnyPublisher<[WalletConnectSession], Never> {
        walletConnectMetadata.v1Sessions
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private func store(sessions: [WalletConnectSession]) -> AnyPublisher<Void, Never> {
        walletConnectMetadata
            .update(v1Sessions: sessions)
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }
}
