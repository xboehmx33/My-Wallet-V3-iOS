import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// A TextField that is backed by UIKit that allows us to get/set its first responder state
struct FocusableTextField: UIViewRepresentable {

    @Binding private var isFirstResponder: Bool
    @Binding private var text: String

    private var configuration = { (_: UITextField) in }
    private var onReturnTapped = {}

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        configuration: @escaping (UITextField) -> Void = { _ in },
        onReturnTapped: @escaping () -> Void = {}
    ) {
        self.configuration = configuration
        _text = text
        _isFirstResponder = isFirstResponder
        self.onReturnTapped = onReturnTapped
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addTarget(context.coordinator, action: #selector(Coordinator.textViewDidChange), for: .editingChanged)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        configuration(uiView)
        switch isFirstResponder {
        case true:
            uiView.becomeFirstResponder()
        case false:
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder, onReturnTapped: onReturnTapped)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>
        var onReturnTapped: () -> Void

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>, onReturnTapped: @escaping () -> Void) {
            self.text = text
            self.isFirstResponder = isFirstResponder
            self.onReturnTapped = onReturnTapped
        }

        @objc func textViewDidChange(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFirstResponder.wrappedValue = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFirstResponder.wrappedValue = false
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onReturnTapped()
            return true
        }
    }
}

struct FocusableTextField_Previews: PreviewProvider {
    static var previews: some View {
        FocusableTextField(
            text: .constant("test@example.com"),
            isFirstResponder: .constant(false)
        )
        .padding()
    }
}
#endif
