// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI
import UIComponentsKit

struct HeaderView: View {
    let viewModel: HeaderStyle

    @Binding var searchText: String?
    @Binding var isSearching: Bool

    var body: some View {
        switch viewModel {
        case .none:
            EmptyView()
        case .simple(subtitle: let subtitle):
            SimpleHeaderView(subtitle: subtitle)
        case .normal(
            title: let title,
            subtitle: let subtitle,
            image: let image,
            tableTitle: let tableTitle,
            searchable: let searchable
        ):
            NormalHeaderView(
                title: title,
                subtitle: subtitle,
                image: image,
                tableTitle: tableTitle,
                searchable: searchable,
                searchText: $searchText,
                isSearching: $isSearching
            )
        }
    }
}

private struct NormalHeaderView: View {
    let title: String
    let subtitle: String
    let image: Image?
    let tableTitle: String?
    let searchable: Bool

    @Binding var searchText: String?
    @Binding var isSearching: Bool

    private enum Layout {
        static let margins = EdgeInsets(top: 24, leading: 24, bottom: 0, trailing: 24)

        static let titleTopPadding: CGFloat = 18
        static let subtitleTopPadding: CGFloat = 8
        static let tableTitleTopPadding: CGFloat = 27
        static let dividerLineTopPadding: CGFloat = 8

        static let imageSize = CGSize(width: 32, height: 32)
        static let dividerLineHeight: CGFloat = 1
        static let titleFontSize: CGFloat = 20
        static let subtitleFontSize: CGFloat = 14
        static let tableTitleFontSize: CGFloat = 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isSearching {
                VStack(alignment: .leading, spacing: 0) {
                    image?
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.imageSize.width, height: Layout.imageSize.height)
                        .padding(.top, Layout.margins.top)

                    Text(title)
                        .font(Font(weight: .semibold, size: Layout.titleFontSize))
                        .foregroundColor(.textTitle)
                        .padding(.top, Layout.titleTopPadding)

                    Text(subtitle)
                        .font(Font(weight: .medium, size: Layout.subtitleFontSize))
                        .foregroundColor(.textSubheading)
                        .padding(.top, Layout.subtitleTopPadding)
                }
                .padding(.trailing, Layout.margins.trailing)
            }

            if searchable {
                SearchBar(text: $searchText, isActive: $isSearching)
                    .padding(.trailing, Layout.margins.trailing - 8)
                    .padding(.leading, -8)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(tableTitle ?? "")
                        .font(Font(weight: .semibold, size: Layout.tableTitleFontSize))
                        .foregroundColor(.textTitle)
                        .padding(.top, Layout.tableTitleTopPadding)

                    Rectangle()
                        .frame(height: Layout.dividerLineHeight)
                        .padding(.leading, Layout.dividerLineTopPadding)
                        .padding(.trailing, Layout.margins.bottom)
                        .foregroundColor(.dividerLineLight)
                }
            }
        }
        .padding(.leading, Layout.margins.leading)
        .background(
            ImageAsset.linkPattern.image
                .resizable()
                .scaledToFill()
                .mask(
                    LinearGradient(
                        gradient: Gradient(
                            stops: [
                                .init(color: .black.opacity(1.0), location: 0.0),
                                .init(color: .black.opacity(0.1), location: 0.6),
                                .init(color: .black.opacity(0.0), location: 0.9),
                                .init(color: .black.opacity(0.0), location: 1.0)
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isSearching ? 0.0 : 1.0)
        )
        .animation(.easeInOut, value: isSearching)
    }
}

private struct SimpleHeaderView: View {
    let subtitle: String

    private enum Layout {
        static let margins = EdgeInsets(top: 23.5, leading: 24, bottom: 23.5, trailing: 24)

        static let dividerLineHeight: CGFloat = 1
        static let subtitleFontSize: CGFloat = 14
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
            Text(subtitle)
                .font(Font(weight: .medium, size: Layout.subtitleFontSize))
                .foregroundColor(.textSubheading)
                .padding(Layout.margins)

            Rectangle()
                .frame(height: Layout.dividerLineHeight)
                .foregroundColor(.dividerLineLight)
        }
    }
}

private struct SearchBar: UIViewRepresentable {
    @Binding var text: String?
    @Binding var isActive: Bool

    func makeUIView(context: Context) -> UISearchBar {
        let view = UISearchBar()
        view.searchBarStyle = .minimal
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
        if isActive {
            uiView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(searchText: $text, isActive: $isActive)
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var searchText: String?
        @Binding var isActive: Bool

        init(searchText: Binding<String?>, isActive: Binding<Bool>) {
            _searchText = searchText
            _isActive = isActive
            super.init()
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.searchText = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            isActive = true
            searchBar.setShowsCancelButton(true, animated: true)
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true)
            isActive = false
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchText = nil
            searchBar.resignFirstResponder()
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContainer()
            .previewLayout(.sizeThatFits)
    }

    struct PreviewContainer: View {
        @State var searchText: String?
        @State var isSearching: Bool = false

        var body: some View {
            HeaderView(
                viewModel: .normal(
                    title: "Receive Crypto Now",
                    subtitle: "Choose a Wallet to receive crypto to.",
                    image: ImageAsset.iconReceive.image,
                    tableTitle: nil,
                    searchable: true
                ),
                searchText: $searchText,
                isSearching: $isSearching
            )
            .animation(.easeInOut, value: isSearching)
        }
    }
}
