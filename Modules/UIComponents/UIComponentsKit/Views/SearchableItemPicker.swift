// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import Foundation
import Localization
import SwiftUI
import ToolKit

public struct SearchableItem<Identifier: Hashable>: Identifiable, CustomStringConvertible {

    public let id: Identifier
    public let title: String

    public var description: String {
        title
    }

    public init(id: Identifier, title: String) {
        self.id = id
        self.title = title
    }
}

extension SearchableItem: Equatable {

    public static func == (lhs: SearchableItem, rhs: SearchableItem) -> Bool {
        lhs.id == rhs.id
    }
}

public struct SearchableItemPicker<Identifier: Hashable>: View {

    public struct SearchableSection: Identifiable {

        public let id: AnyHashable
        public let title: String?
        public let items: [SearchableItem<Identifier>]

        public init(
            title: String?,
            items: [SearchableItem<Identifier>],
            id: AnyHashable = UUID()
        ) {
            self.id = id
            self.title = title
            self.items = items
        }
    }

    private let sections: [SearchableSection]
    private let selectedItem: SearchableItem<Identifier>?
    private let cancelButtonTitle: String
    private let searchPlaceholder: String
    private let searchTolerance: Double
    private let onSelection: (SearchableItem<Identifier>) -> Void

    @State private var searching: Bool = false
    @State private var searchQuery: String = ""

    public init(
        sections: [SearchableSection],
        selectedItem: SearchableItem<Identifier>? = nil,
        cancelButtonTitle: String = "",
        searchPlaceholder: String = "",
        searchTolerance: Double = 0.3,
        onSelection: @escaping (SearchableItem<Identifier>) -> Void
    ) {
        self.sections = sections
        self.selectedItem = selectedItem
        self.cancelButtonTitle = cancelButtonTitle
        self.searchPlaceholder = searchPlaceholder
        self.searchTolerance = searchTolerance
        self.onSelection = onSelection
    }

    public var body: some View {
        VStack(spacing: Spacing.padding3) {
            searchBar
                .padding(.horizontal, Spacing.padding3)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    ForEach(sections) { section in
                        if let title = section.title {
                            Section(header: SectionHeader(title: title)) {
                                ForEach(filtered(section.items)) { item in
                                    cell(for: item)
                                    PrimaryDivider()
                                }
                            }
                            .textCase(nil) // prevents header from being uppercased
                            .listRowInsets(EdgeInsets())
                        } else {
                            Section {
                                ForEach(filtered(section.items)) { item in
                                    cell(for: item)
                                    PrimaryDivider()
                                }
                            }
                            .textCase(nil) // prevents header from being uppercased
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
        }
    }

    var searchBar: some View {
        SearchBar(
            text: $searchQuery,
            isFirstResponder: $searching,
            cancelButtonText: cancelButtonTitle,
            placeholder: searchPlaceholder,
            onReturnTapped: {
                searching = true
            }
        )
    }

    @ViewBuilder
    private func cell(for item: SearchableItem<Identifier>) -> some View {
        PrimaryRow(
            title: item.title,
            subtitle: String(describing: item.id),
            trailing: {
                if item == selectedItem {
                    Icon.checkCircle
                        .frame(width: 16, height: 16)
                        .accentColor(.semantic.success)
                } else {
                    EmptyView()
                }
            }
        )
        .onTapGesture {
            onSelection(item)
        }
    }

    private func filtered(_ items: [SearchableItem<Identifier>]) -> [SearchableItem<Identifier>] {
        guard !searchQuery.isEmpty else {
            return items
        }
        return items.filter {
            let searchDistance = $0.title.distance(
                between: searchQuery,
                using: FuzzyAlgorithm(caseInsensitive: true)
            )
            return searchDistance <= searchTolerance
        }
    }
}
