import SwiftUI

public struct NavigationLinkProviderView: View {
    let data: NavigationLinkProviderList

    public var body: some View {
        List {
            NavigationLinkProvider.sections(for: data)
        }
        .listStyle(PlainListStyle())
        .background(Color.semantic.background.ignoresSafeArea())
    }
}

struct NavigationLinkProviderView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(
            ColorScheme.allCases,
            id: \.self,
            content: NavigationLinkProviderView(
                data: [
                    "Mock": [
                        NavigationLinkProvider(view: Text("Chedder"), title: "🧀 Cheese")
                    ]
                ]
            ).preferredColorScheme
        )
    }
}
