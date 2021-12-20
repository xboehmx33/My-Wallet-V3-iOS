// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import Localization
import SwiftUI
import UIComponentsKit

public struct StatePickerView: View {

    private typealias LocalizedStrings = LocalizationConstants.Authentication.CountryAndStatePickers

    public static let usaStates = [
        SearchableItem(id: "AK", title: "Alaska"),
        SearchableItem(id: "AL", title: "Alabama"),
        SearchableItem(id: "AR", title: "Arkansas"),
        SearchableItem(id: "AS", title: "American Samoa"),
        SearchableItem(id: "AZ", title: "Arizona"),
        SearchableItem(id: "CA", title: "California"),
        SearchableItem(id: "CO", title: "Colorado"),
        SearchableItem(id: "CT", title: "Connecticut"),
        SearchableItem(id: "DC", title: "District of Columbia"),
        SearchableItem(id: "DE", title: "Delaware"),
        SearchableItem(id: "FL", title: "Florida"),
        SearchableItem(id: "GA", title: "Georgia"),
        SearchableItem(id: "GU", title: "Guam"),
        SearchableItem(id: "HI", title: "Hawaii"),
        SearchableItem(id: "IA", title: "Iowa"),
        SearchableItem(id: "ID", title: "Idaho"),
        SearchableItem(id: "IL", title: "Illinois"),
        SearchableItem(id: "IN", title: "Indiana"),
        SearchableItem(id: "KS", title: "Kansas"),
        SearchableItem(id: "KY", title: "Kentucky"),
        SearchableItem(id: "LA", title: "Louisiana"),
        SearchableItem(id: "MA", title: "Massachusetts"),
        SearchableItem(id: "MD", title: "Maryland"),
        SearchableItem(id: "ME", title: "Maine"),
        SearchableItem(id: "MI", title: "Michigan"),
        SearchableItem(id: "MN", title: "Minnesota"),
        SearchableItem(id: "MO", title: "Missouri"),
        SearchableItem(id: "MS", title: "Mississippi"),
        SearchableItem(id: "MT", title: "Montana"),
        SearchableItem(id: "NC", title: "North Carolina"),
        SearchableItem(id: "ND", title: "North Dakota"),
        SearchableItem(id: "NE", title: "Nebraska"),
        SearchableItem(id: "NH", title: "New Hampshire"),
        SearchableItem(id: "NJ", title: "New Jersey"),
        SearchableItem(id: "NM", title: "New Mexico"),
        SearchableItem(id: "NV", title: "Nevada"),
        SearchableItem(id: "NY", title: "New York"),
        SearchableItem(id: "OH", title: "Ohio"),
        SearchableItem(id: "OK", title: "Oklahoma"),
        SearchableItem(id: "OR", title: "Oregon"),
        SearchableItem(id: "PA", title: "Pennsylvania"),
        SearchableItem(id: "PR", title: "Puerto Rico"),
        SearchableItem(id: "RI", title: "Rhode Island"),
        SearchableItem(id: "SC", title: "South Carolina"),
        SearchableItem(id: "SD", title: "South Dakota"),
        SearchableItem(id: "TN", title: "Tennessee"),
        SearchableItem(id: "TX", title: "Texas"),
        SearchableItem(id: "UT", title: "Utah"),
        SearchableItem(id: "VA", title: "Virginia"),
        SearchableItem(id: "VI", title: "Virgin Islands"),
        SearchableItem(id: "VT", title: "Vermont"),
        SearchableItem(id: "WA", title: "Washington"),
        SearchableItem(id: "WI", title: "Wisconsin"),
        SearchableItem(id: "WV", title: "West Virginia"),
        SearchableItem(id: "WY", title: "Wyoming")
    ]

    private let selectedItem: SearchableItem<String>?
    private let onSelection: (SearchableItem<String>) -> Void

    public init(
        selectedItem: SearchableItem<String>?,
        onSelection: @escaping (SearchableItem<String>) -> Void
    ) {
        self.selectedItem = selectedItem
        self.onSelection = onSelection
    }

    public var body: some View {
        SearchableItemPicker(
            sections: [
                .init(
                    title: LocalizedStrings.statesSectionTitle,
                    items: StatePickerView.usaStates
                )
            ],
            selectedItem: selectedItem,
            cancelButtonTitle: LocalizationConstants.searchCancelButtonTitle,
            searchPlaceholder: LocalizationConstants.searchPlaceholder,
            onSelection: onSelection
        )
    }
}
