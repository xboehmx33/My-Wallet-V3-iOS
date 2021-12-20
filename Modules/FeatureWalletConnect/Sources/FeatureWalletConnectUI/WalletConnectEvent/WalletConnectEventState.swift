// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import FeatureWalletConnectDomain
import Foundation
import Localization
import SwiftUI
import UIComponentsKit
import WalletConnectSwift

public struct WalletConnectEventState: Equatable {
    enum ConnectionState: Equatable {
        case idle
        case success
        case fail
        case details
    }

    let session: Session
    let state: ConnectionState
    let imageResource: ImageResource?
    let title: String
    var subtitle: String?
    var primaryButtonTitle: String?
    var secondaryButtonTitle: String?
    var primaryAction: WalletConnectEventAction?
    var secondaryAction: WalletConnectEventAction?
    var decorationImage: UIImage?
    var secondaryButtonColor: Color = .buttonSecondaryText

    init(session: Session, state: ConnectionState) {
        self.state = state
        self.session = session

        let meta = session.dAppInfo.peerMeta

        if let url = meta.icons.first {
            imageResource = .remote(url: url)
        } else {
            imageResource = nil
        }

        switch state {
        case .idle:
            title = String(format: LocalizationConstants.WalletConnect.dAppWantsToConnect, meta.name)
            subtitle = meta.url.host
            secondaryButtonTitle = LocalizationConstants.cancel
            primaryButtonTitle = LocalizationConstants.WalletConnect.confirm
            primaryAction = .accept
            secondaryAction = .close
        case .fail:
            title = String(format: LocalizationConstants.WalletConnect.dAppConnectionFail, meta.name)
            subtitle = LocalizationConstants.WalletConnect.dAppConnectionFailMessage
            primaryButtonTitle = LocalizationConstants.okString
            primaryAction = .close
            decorationImage = UIImage(named: "fail-decorator", in: .featureWalletConnectUI, with: nil)!
        case .success:
            title = String(format: LocalizationConstants.WalletConnect.dAppConnectionSuccess, meta.name)
            primaryButtonTitle = LocalizationConstants.okString
            primaryAction = .close
            decorationImage = UIImage(named: "success-decorator", in: .featureWalletConnectUI, with: nil)!
        case .details:
            title = meta.name
            subtitle = meta.description
            secondaryButtonTitle = LocalizationConstants.WalletConnect.disconnect
            secondaryAction = .disconnect
            secondaryButtonColor = .textError
        }
    }

    func analyticsEvent(for action: WalletConnectEventAction) -> AnalyticsEvent? {
        switch state {
        case .idle:
            switch action {
            case .accept:
                return AnalyticsEvents
                    .New
                    .WalletConnect
                    .dappConnectionActioned(
                        action: .confirm,
                        appName: session.dAppInfo.peerMeta.name
                    )
            case .close:
                return AnalyticsEvents
                    .New
                    .WalletConnect
                    .dappConnectionActioned(
                        action: .cancel,
                        appName: session.dAppInfo.peerMeta.name
                    )
            default:
                return nil
            }
        case .fail:
            return AnalyticsEvents
                .New
                .WalletConnect
                .dappConnectionRejected(appName: session.dAppInfo.peerMeta.name)
        case .success:
            return AnalyticsEvents
                .New
                .WalletConnect
                .dappConnectionConfirmed(appName: session.dAppInfo.peerMeta.name)
        case .details:
            switch action {
            case .disconnect:
                return AnalyticsEvents
                    .New
                    .WalletConnect
                    .connectedDappActioned(
                        action: .disconnect,
                        appName: session.dAppInfo.peerMeta.name,
                        origin: .appsList
                    )
            case .openWebsite:
                return AnalyticsEvents
                    .New
                    .WalletConnect
                    .connectedDappActioned(
                        action: .launch,
                        appName: session.dAppInfo.peerMeta.name,
                        origin: .appsList
                    )
            default:
                return nil
            }
        }
    }
}
