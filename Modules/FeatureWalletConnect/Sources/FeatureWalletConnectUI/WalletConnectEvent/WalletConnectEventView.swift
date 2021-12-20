// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import FeatureWalletConnectDomain
import SwiftUI
import UIComponentsKit
import WalletConnectSwift

struct WalletConnectEventView: View {
    private let store: Store<WalletConnectEventState, WalletConnectEventAction>

    init(store: Store<WalletConnectEventState, WalletConnectEventAction>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 100)
                            .frame(width: 32, height: 4)
                            .foregroundColor(.borderPrimary)
                            .offset(x: 16, y: -6)
                        Spacer()
                        Button(action: {
                            viewStore.send(.close)
                        }, label: {
                            Image(uiImage: UIImage(named: "close-button", in: .featureWalletConnectUI, with: nil)!)
                                .resizable()
                                .frame(width: 32, height: 32)
                        })
                    }
                    if let imageResource = viewStore.imageResource {
                        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                            ImageResourceView(imageResource, placeholder: { Color.viewPrimaryBackground })
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .cornerRadius(13)
                            if let decorationImage = viewStore.decorationImage {
                                Image(uiImage: decorationImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .offset(x: 15, y: -15)
                            }
                        }
                    }
                    Text(viewStore.title)
                        .typography(.title3)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(viewStore.subtitle ?? "")
                        .typography(.paragraph1)
                        .foregroundColor(.textSubheading)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 32)
                    if let secondaryButtonTitle = viewStore.secondaryButtonTitle,
                       let secondaryAction = viewStore.secondaryAction
                    {
                        Button(secondaryButtonTitle) {
                            viewStore.send(secondaryAction)
                        }
                        .buttonStyle(
                            SecondaryButtonStyle(
                                isEnabled: true,
                                foregroundColor: viewStore.secondaryButtonColor
                            )
                        )
                    }
                    if let primaryButtonTitle = viewStore.primaryButtonTitle,
                       let primaryAction = viewStore.primaryAction
                    {
                        PrimaryButton(title: primaryButtonTitle) {
                            viewStore.send(primaryAction)
                        }
                    }
                }
                .padding(24)
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onEnded { drag in
                        if drag.translation.height >= 20 {
                            viewStore.send(.close)
                        }
                    }
            )
        }
    }
}

// MARK: SwiftUI Preview

#if DEBUG
let meta = Session.ClientMeta(
    name: "Uniswap Interface",
    description: "Swap or provide liquidity on the Uniswap Protocol",
    icons: [URL(string: "https://app.uniswap.org/./images/512x512_App_Icon.png")!],
    url: URL(string: "https://app.uniswap.org")!
)

let dAppInfo = Session.DAppInfo(peerId: "", peerMeta: meta)
let walletInfo = Session.WalletInfo(
    approved: true,
    accounts: [],
    chainId: 1,
    peerId: "",
    peerMeta: meta
)

let session = Session(
    url: WCURL(topic: "", bridgeURL: URL(string: "blockchain.com")!, key: ""),
    dAppInfo: dAppInfo,
    walletInfo: walletInfo
)

class MockWalletConnectService: WalletConnectServiceAPI {
    var sessionEvents: AnyPublisher<WalletConnectSessionEvent, Never> {
        Future<WalletConnectSessionEvent, Never> { _ in }
            .eraseToAnyPublisher()
    }

    var userEvents: AnyPublisher<WalletConnectUserEvent, Never> {
        Future<WalletConnectUserEvent, Never> { _ in }
            .eraseToAnyPublisher()
    }

    func connect(_ url: String) {}
    func disconnect(_ session: Session) {}
    func acceptConnection(_ completion: @escaping (Session.WalletInfo) -> Void) {}
    func denyConnection(_ completion: @escaping (Session.WalletInfo) -> Void) {}
}

class MockWalletConnectRouter: WalletConnectRouterAPI {
    func showConnectedDApps(_ completion: (() -> Void)?) {}
    func showSessionDetails(session: WalletConnectSession) -> AnyPublisher<Void, Never> {
        .just(())
    }

    func openWebsite(for client: Session.ClientMeta) {}
}

class MockAnalyticsRecorder: AnalyticsEventRecorderAPI {
    func record(event: AnalyticsEvent) {}
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {

        let environment = WalletConnectEventEnvironment(
            mainQueue: .main,
            service: MockWalletConnectService(),
            router: MockWalletConnectRouter(),
            analyticsEventRecorder: MockAnalyticsRecorder(),
            onComplete: { _ in }
        )
        let store = Store(
            initialState: WalletConnectEventState(session: session, state: .idle),
            reducer: walletConnectEventReducer,
            environment: environment
        )
        return WalletConnectEventView(store: store)
    }
}
#endif
