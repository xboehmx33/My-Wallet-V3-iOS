// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

extension View {

    /// Display a bottom sheet over the current content
    /// - Parameters:
    ///   - isPresented: A binding which determines when the content should be shown
    ///   - maximumHeight: The maximum height the sheet can reach, defaults to 70% of the viewport height
    ///   - content: The contents of the sheet
    /// - Returns: ZStack containing `self` overlayed with the bottom sheet view
    @ViewBuilder
    public func bottomSheet<Content>(
        isPresented: Binding<Bool>,
        maximumHeight: Length = 70.vh,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        ZStack {
            zIndex(0)
            if isPresented.transaction(isPresented.transaction).wrappedValue {
                Color.palette.overlay600
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                    .onTapGesture {
                        isPresented.wrappedValue = false
                    }
            }
            BottomSheetView(
                isPresented: isPresented,
                maximumHeight: maximumHeight,
                content: content
            )
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .zIndex(2)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .animation(.interactiveSpring())
    }
}

/// A small sheet used to present content from a drawer.
/// The content presented will be dismissed via the user swiping down, using the handle,
/// tapping the handle or by tapping the faded area behind the presented sheet.
///
/// # Figma
/// [Sheet](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=209%3A10112)
public struct BottomSheetView<Content: View>: View {

    @Binding var isPresented: Bool

    let maximumHeight: Length
    let content: () -> Content

    @GestureState private var translation: CGFloat = 0

    public init(
        isPresented: Binding<Bool>,
        maximumHeight: Length,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maximumHeight = maximumHeight
        self.content = content
        _isPresented = isPresented
    }

    @State private var height: CGFloat = 0

    public var body: some View {
        GeometryReader { geometry in
            let maximumHeight = maximumHeight.in(geometry)
            VStack(spacing: 0) {
                indicator
                    .padding()
                content()
            }
            .padding(.bottom, 20.pt)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { height = min(geometry.size.height, maximumHeight) }
                }
            )
            .frame(
                width: geometry.size.width,
                height: height,
                alignment: .top
            )
            .background(Color.semantic.background)
            .cornerRadius(24)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(
                y: max((isPresented ? 0 : height) + translation, 0)
            )
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        guard abs(value.translation.height) > maximumHeight / 4 else { return }
                        isPresented = value.translation.height < 0
                    }
            )
        }
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.semantic.dark)
            .frame(width: 32.pt, height: 4.pt)
            .onTapGesture {
                isPresented.toggle()
            }
    }
}

struct BottomSheetView_Previews: PreviewProvider {

    static var previews: some View {
        Color.gray
            .overlay(
                BottomSheetView(
                    isPresented: .constant(true),
                    maximumHeight: 70.vh
                ) {
                    ForEach(0..<10) { i in
                        PrimaryRow(title: "\(i)")
                            .accentColor(.semantic.muted)
                        if i != 9 {
                            Divider()
                        }
                    }
                }
            )
            .ignoresSafeArea()
    }
}
