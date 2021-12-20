// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import RxSwift

final class SettingsSectionsProvider {

    var states: Observable<SettingSectionsLoadingStates> {
        Observable
            .combineLatest(
                presenters[.help]!.state,
                presenters[.connect]!.state,
                presenters[.banks]!.state,
                presenters[.cards]!.state,
                presenters[.security]!.state,
                presenters[.profile]!.state,
                presenters[.preferences]!.state
            ) { (about: $0, connect: $1, banks: $2, cards: $3, security: $4, profile: $5, preferences: $6) }
            .map { states in
                SettingSectionsLoadingStates(statePerSection: [
                    .help: states.about,
                    .connect: states.connect,
                    .banks: states.banks,
                    .cards: states.cards,
                    .security: states.security,
                    .profile: states.profile,
                    .preferences: states.preferences
                ])
            }
            .share()
    }

    var sections: Observable<[SettingsSectionViewModel]> {
        states
            .map(\.all)
            .map { $0.compactMap(\.value) }
            .map { $0.compactMap(\.viewModel) }
            .map { $0.sorted(by: { $0.sectionType.rawValue < $1.sectionType.rawValue }) }
    }

    private var all: [SettingsSectionPresenting] {
        Array(presenters.values)
    }

    private var presenters: [SettingsSectionType: SettingsSectionPresenting] = [:]

    init(
        about: SettingsSectionPresenting,
        connect: SettingsSectionPresenting,
        banks: SettingsSectionPresenting,
        cards: SettingsSectionPresenting,
        security: SettingsSectionPresenting,
        profile: SettingsSectionPresenting,
        preferences: SettingsSectionPresenting
    ) {
        presenters[.profile] = profile
        presenters[.help] = about
        presenters[.connect] = connect
        presenters[.banks] = banks
        presenters[.cards] = cards
        presenters[.security] = security
        presenters[.preferences] = preferences
    }
}
