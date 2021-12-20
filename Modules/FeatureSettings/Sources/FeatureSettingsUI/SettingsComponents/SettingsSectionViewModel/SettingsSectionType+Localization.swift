// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization

extension SettingsSectionType {
    var sectionTitle: String {
        switch self {
        case .profile:
            return LocalizationConstants.Settings.Section.profile
        case .preferences:
            return LocalizationConstants.Settings.Section.preferences
        case .connect:
            return LocalizationConstants.Settings.Section.walletConnect
        case .security:
            return LocalizationConstants.Settings.Section.security
        case .cards:
            return LocalizationConstants.Settings.Section.linkedCards
        case .banks:
            return LocalizationConstants.Settings.Section.linkedBanks
        case .help:
            return LocalizationConstants.Settings.Section.help
        }
    }
}
