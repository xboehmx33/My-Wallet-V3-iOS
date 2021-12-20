// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct PageControlExamples: View {
    @State var firstSelection: AnyHashable = "first"

    var body: some View {
        VStack(spacing: Spacing.padding1) {
            TabController()
                .frame(width: 320, height: 200)
        }
        .padding(Spacing.padding())
    }

    struct TabController: View {

        let controls: [Color] = [
            Color.red,
            Color.green,
            Color.blue
        ]
        @State var selection: Color

        init() {
            _selection = State(initialValue: controls[0])
        }

        var body: some View {
            ZStack {
                HStack(spacing: 0) {
                    controlView(control: controls[0])
                    controlView(control: controls[1])
                    controlView(control: controls[2])
                }
                VStack {
                    Spacer()
                    PageControl(
                        controls: controls,
                        selection: $selection
                    )
                }
            }
        }

        @ViewBuilder private func controlView(control: Color) -> some View {
            control
                .onTapGesture { selection = control }
                .overlay(
                    Text("selected")
                        .foregroundColor(.white)
                        .opacity(selection == control ? 1 : 0)
                )
        }
    }
}

struct PageControlExamples_Previews: PreviewProvider {
    static var previews: some View {
        PageControlExamples()
    }
}
