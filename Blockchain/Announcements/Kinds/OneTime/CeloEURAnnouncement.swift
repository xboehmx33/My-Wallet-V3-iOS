// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import SwiftUI
import ToolKit

/// This is an announcement that introduces CeloEUR draw.
final class CeloEURAnnouncement: OneTimeAnnouncement, ActionableAnnouncement {

    private typealias LocalizedString = LocalizationConstants.AnnouncementCards.CeloEUR

    // MARK: - Properties

    var viewModel: AnnouncementCardViewModel {
        let button = ButtonViewModel.primary(
            with: LocalizedString.ctaButton,
            background: .primaryButton
        )
        button.tapRelay
            .bind { [weak self] in
                guard let self = self else { return }
                self.analyticsRecorder.record(
                    event: self.actionAnalyticsEvent
                )
                self.markRemoved()
                self.action()
                self.dismiss()
            }
            .disposed(by: disposeBag)

        return AnnouncementCardViewModel(
            type: type,
            badgeImage: .init(
                image: celoEUR!.logoResource,
                contentColor: nil,
                backgroundColor: .clear,
                cornerRadius: .round,
                size: .edge(40)
            ),
            title: LocalizedString.title,
            description: LocalizedString.description,
            buttons: [button],
            dismissState: .dismissible { [weak self] in
                guard let self = self else { return }
                self.analyticsRecorder.record(event: self.dismissAnalyticsEvent)
                self.markRemoved()
                self.dismiss()
            },
            didAppear: { [weak self] in
                guard let self = self else { return }
                self.analyticsRecorder.record(event: self.didAppearAnalyticsEvent)
            }
        )
    }

    var shouldShow: Bool {
        !isDismissed
            && celoEURCurrencyExists
            && validKYCTier
            && validCountry
    }

    let key: AnnouncementRecord.Key = .celoEUR
    let type: AnnouncementType = .celoEUR
    let analyticsRecorder: AnalyticsEventRecorderAPI

    let dismiss: CardAnnouncementAction
    let recorder: AnnouncementRecorder
    let action: CardAnnouncementAction

    private var celoEURCurrencyExists: Bool {
        celoEUR != nil
    }

    private var validKYCTier: Bool {
        !tiers.isTier0
    }

    private var validCountry: Bool {
        guard let userCountry = userCountry else {
            return false
        }
        let isInDisallowedCountries = [Country.US, .IT]
            .contains(userCountry)
        return !isInDisallowedCountries
    }

    private let celoEUR: CryptoCurrency?
    private let tiers: KYC.UserTiers
    private let userCountry: Country?
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        celoEUR: CryptoCurrency?,
        tiers: KYC.UserTiers,
        userCountry: Country?,
        cacheSuite: CacheSuite = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        errorRecorder: ErrorRecording = resolve(),
        dismiss: @escaping CardAnnouncementAction,
        action: @escaping CardAnnouncementAction
    ) {
        recorder = AnnouncementRecorder(cache: cacheSuite, errorRecorder: errorRecorder)
        self.userCountry = userCountry
        self.celoEUR = celoEUR
        self.tiers = tiers
        self.analyticsRecorder = analyticsRecorder
        self.dismiss = dismiss
        self.action = action
    }
}

// MARK: SwiftUI Preview

#if DEBUG
struct CeloEURAnnouncementContainer: UIViewRepresentable {
    typealias UIViewType = AnnouncementCardView

    func makeUIView(context: Context) -> UIViewType {
        let presenter = CeloEURAnnouncement(
            celoEUR: .coin(.bitcoin),
            tiers: KYC.UserTiers(
                tiers: [
                    KYC.UserTier(tier: .tier0, state: .verified),
                    KYC.UserTier(tier: .tier1, state: .verified)
                ]
            ),
            userCountry: .ES,
            dismiss: {},
            action: {}
        )
        return AnnouncementCardView(using: presenter.viewModel)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct CeloEURAnnouncementContainer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CeloEURAnnouncementContainer().colorScheme(.light)
        }.previewLayout(.fixed(width: 375, height: 250))
    }
}
#endif
