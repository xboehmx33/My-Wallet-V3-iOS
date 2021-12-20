// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import SwiftUI

/// A simple class required to update the state of `ErrorRecoveryCTA` from `UIKIt`
class ErrorRecoveryCTAModel: ObservableObject {

    @Published var buttonTitle: String
    let action: () -> Void

    init(buttonTitle: String, action: @escaping () -> Void) {
        self.buttonTitle = buttonTitle
        self.action = action
    }
}

/// A simple `SwiftUI.View` that wraps a warning button from `ComponentsLibrary`
/// This is required because `EnterAmountViewController` is still using `RIB`s and `UIKit` and we need to change the state of the button from there.
struct ErrorRecoveryCTA: View {

    /// Save the instance of this object and update it to have the changes be reflected in `ErrorRecoveryCTA`
    @StateObject var model: ErrorRecoveryCTAModel

    var body: some View {
        AlertButton(
            title: model.buttonTitle,
            action: model.action
        )
    }
}

struct ErrorRecoveryCTA_Previews: PreviewProvider {

    static var previews: some View {
        ErrorRecoveryCTA(
            model: ErrorRecoveryCTAModel(
                buttonTitle: "TEST TITLE",
                action: {}
            )
        )
    }
}
