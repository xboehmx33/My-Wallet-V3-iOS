// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import WalletConnectSwift

public protocol SessionRepositoryAPI {
    func contains(session: WalletConnectSession) -> AnyPublisher<Bool, Never>
    func store(session: WalletConnectSession) -> AnyPublisher<Void, Never>
    func remove(session: WalletConnectSession) -> AnyPublisher<Void, Never>
    func removeAll() -> AnyPublisher<Void, Never>
    func retrieve() -> AnyPublisher<[WalletConnectSession], Never>
}

extension SessionRepositoryAPI {

    public func contains(session: Session) -> AnyPublisher<Bool, Never> {
        contains(
            session: WalletConnectSession(session: session)
        )
    }

    public func store(session: Session) -> AnyPublisher<Void, Never> {
        store(
            session: WalletConnectSession(session: session)
        )
    }

    public func remove(session: Session) -> AnyPublisher<Void, Never> {
        remove(
            session: WalletConnectSession(session: session)
        )
    }
}
