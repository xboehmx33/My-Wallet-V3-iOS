// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public protocol ExternalActionsProviderAPI {
    func logout()
    func handleAccountsAndAddresses()
    func handleAirdrops()
    func handleSupport()
    func handleSecureChannel()
}
