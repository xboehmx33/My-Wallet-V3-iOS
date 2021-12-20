// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

public struct RootView: View {

    @State var colorScheme: ColorScheme

    private let data: NavigationLinkProviderList = [
        "1 - Base": [
            NavigationLinkProvider(view: ColorsExamplesView(), title: "🌈 Colors"),
            NavigationLinkProvider(view: TypographyExamplesView(), title: "🔠 Typography"),
            NavigationLinkProvider(view: SpacingExamplesView(), title: "🔳 Spacing Rules"),
            NavigationLinkProvider(view: IconsExamplesView(), title: "🖼 Icons")
        ],
        "2 - Primitives": [
            NavigationLinkProvider(view: TabBarExamplesView(), title: "🎼 TabBar"),
            NavigationLinkProvider(view: ButtonExamplesView(), title: "🕹 Buttons"),
            NavigationLinkProvider(view: PrimaryDividerExamples(), title: "🗂 Dividers"),
            NavigationLinkProvider(view: PrimarySwitchExamples(), title: "🔘 PrimarySwitch"),
            NavigationLinkProvider(view: TagExamples(), title: "🏷 Tag"),
            NavigationLinkProvider(view: CheckboxExamples(), title: "✅ Checkbox"),
            NavigationLinkProvider(view: RichTextExamples(), title: "🤑 Rich Text"),
            NavigationLinkProvider(view: SegmentedControlExamples(), title: "🚥 SegmentedControl"),
            NavigationLinkProvider(view: InputExamples(), title: "⌨️ Input"),
            NavigationLinkProvider(view: PrimaryPickerExamples(), title: "⛏ Picker"),
            NavigationLinkProvider(view: AlertToastExamples(), title: " 🚨 AlertToast"),
            NavigationLinkProvider(view: PageControlExamples(), title: "📑 PageControl")
        ],
        "3 - Compositions": [
            NavigationLinkProvider(view: PrimaryNavigationExamples(), title: "✈️ Navigation"),
            NavigationLinkProvider(view: CalloutCardExamples(), title: "💬 CalloutCard"),
            NavigationLinkProvider(view: SectionHeadersExamples(), title: "🪖 SectionHeaders"),
            NavigationLinkProvider(view: RowExamplesView(), title: "🚣‍♀️ Rows"),
            NavigationLinkProvider(view: BottomSheetExamples(), title: "📄 BottomSheet"),
            NavigationLinkProvider(view: SearchBarExamples(), title: "🔎 SearchBar")
        ]
    ]

    public init(colorScheme: ColorScheme = .light) {
        _colorScheme = State(initialValue: colorScheme)
    }

    public var body: some View {
        PrimaryNavigationView {
            NavigationLinkProviderView(data: data)
                .primaryNavigation(title: "📚 Component Library") {
                    Button("⚫️ / ⚪️") {
                        colorScheme = colorScheme == .light ? .dark : .light
                    }
                }
        }
        .colorScheme(colorScheme)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(
            ColorScheme.allCases,
            id: \.self,
            content: RootView.init(colorScheme:)
        )
    }
}
