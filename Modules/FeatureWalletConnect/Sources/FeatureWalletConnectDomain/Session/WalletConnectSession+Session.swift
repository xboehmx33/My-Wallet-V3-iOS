// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import WalletConnectSwift

extension WalletConnectSession {
    public var session: Session? {
        guard let wcURL = WCURL(url) else {
            return nil
        }
        guard let dAppInfo = dAppInfo.dAppInfo else {
            return nil
        }
        return Session(
            url: wcURL,
            dAppInfo: dAppInfo,
            walletInfo: walletInfo.walletInfo
        )
    }
}

extension WalletConnectSession.WalletInfo {
    fileprivate var walletInfo: Session.WalletInfo {
        Session.WalletInfo(
            approved: true,
            accounts: [],
            chainId: 1,
            peerId: clientId,
            peerMeta: .blockchain
        )
    }
}

extension WalletConnectSession.DAppInfo {
    fileprivate var dAppInfo: Session.DAppInfo? {
        guard let peerMeta = peerMeta.clientMeta else {
            return nil
        }
        return Session.DAppInfo(
            peerId: peerId,
            peerMeta: peerMeta,
            chainId: chainId,
            approved: true
        )
    }
}

extension Session.ClientMeta {
    public static var blockchain: Session.ClientMeta {
        Session.ClientMeta(
            name: "Blockchain.com",
            description: nil,
            icons: [URL(string: "https://www.blockchain.com/static/apple-touch-icon.png")!],
            url: URL(string: "https://blockchain.com")!
        )
    }
}

extension WalletConnectSession.ClientMeta {
    fileprivate var clientMeta: Session.ClientMeta? {
        guard let url = URL(string: url) else {
            return nil
        }
        return Session.ClientMeta(
            name: name,
            description: description,
            icons: icons.compactMap(URL.init),
            url: url
        )
    }
}
