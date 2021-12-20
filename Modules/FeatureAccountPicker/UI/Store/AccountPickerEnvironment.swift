// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineSchedulers
import Foundation
import SwiftUI

public class AccountPickerEnvironment {

    let mainQueue: AnySchedulerOf<DispatchQueue>

    // Effects / Output
    let rowSelected: (AccountPickerRow.ID) -> Void
    let backButtonTapped: () -> Void
    let closeButtonTapped: () -> Void
    let search: (String?) -> Void

    // State / Input
    let sections: () -> AnyPublisher<[AccountPickerRow], Never>

    let updateSingleAccounts: (Set<AnyHashable>)
        -> AnyPublisher<[AnyHashable: AccountPickerRow.SingleAccount.Balances], Error>

    let updateAccountGroups: (Set<AnyHashable>)
        -> AnyPublisher<[AnyHashable: AccountPickerRow.AccountGroup.Balances], Error>

    let header: () -> AnyPublisher<HeaderStyle, Error>

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue> = .main,
        rowSelected: @escaping (AccountPickerRow.ID) -> Void,
        backButtonTapped: @escaping () -> Void,
        closeButtonTapped: @escaping () -> Void,
        search: @escaping (String?) -> Void,
        sections: @escaping () -> AnyPublisher<[AccountPickerRow], Never>,
        // swiftlint:disable line_length
        updateSingleAccounts: @escaping (Set<AnyHashable>) -> AnyPublisher<[AnyHashable: AccountPickerRow.SingleAccount.Balances], Error>,
        updateAccountGroups: @escaping (Set<AnyHashable>) -> AnyPublisher<[AnyHashable: AccountPickerRow.AccountGroup.Balances], Error>,
        // swiftlint:enable line_length
        header: @escaping () -> AnyPublisher<HeaderStyle, Error>
    ) {
        self.mainQueue = mainQueue
        self.rowSelected = rowSelected
        self.backButtonTapped = backButtonTapped
        self.closeButtonTapped = closeButtonTapped
        self.search = search
        self.sections = sections
        self.updateSingleAccounts = updateSingleAccounts
        self.updateAccountGroups = updateAccountGroups
        self.header = header
    }
}
