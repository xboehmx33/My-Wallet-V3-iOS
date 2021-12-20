// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import WalletConnectSwift

public struct WalletConnectSession: Codable, Equatable, Hashable {

    public let url: String
    public let dAppInfo: DAppInfo
    public let walletInfo: WalletInfo

    public struct WalletInfo: Codable, Equatable, Hashable {
        public let clientId: String
        public let sourcePlatform: String
    }

    public struct DAppInfo: Codable, Equatable, Hashable {
        public let peerId: String
        public let peerMeta: ClientMeta
        public let chainId: Int?
    }

    public struct ClientMeta: Codable, Equatable, Hashable {
        public let description: String
        public let url: String
        public let icons: [String]
        public let name: String
    }

    init(session: Session) {
        url = session.url.absoluteString
        dAppInfo = DAppInfo(
            peerId: session.dAppInfo.peerId,
            peerMeta: ClientMeta(
                description: session.dAppInfo.peerMeta.description ?? "",
                url: session.dAppInfo.peerMeta.url.absoluteString,
                icons: session.dAppInfo.peerMeta.icons.map(\.absoluteString),
                name: session.dAppInfo.peerMeta.name
            ),
            chainId: session.dAppInfo.chainId
        )
        walletInfo = WalletInfo(
            clientId: session.walletInfo?.peerId ?? UUID().uuidString,
            sourcePlatform: "ios"
        )
    }
}

extension WalletConnectSession {
    /// Compares two WalletConnectSession based solely on its unique identifier (url).
    public func isEqual(_ rhs: Self) -> Bool {
        url == rhs.url
    }
}
