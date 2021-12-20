// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import RxSwift
import ToolKit

public final class CryptoAddressTextFieldViewModel: TextFieldViewModel {

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - Setup

    public init(
        validator: TextValidating,
        messageRecorder: MessageRecording
    ) {
        super.init(
            with: .cryptoAddress,
            validator: validator,
            messageRecorder: messageRecorder
        )
        let content = ImageViewContent(
            imageResource: .local(name: Icon.qrCode.name, bundle: .componentLibrary)
        )
        let theme = BadgeImageViewModel.Theme(
            backgroundColor: .white,
            cornerRadius: .roundedLow,
            imageViewContent: content,
            marginOffset: 0,
            sizingType: .constant(CGSize(width: 32, height: 20))
        )
        let viewModel = BadgeImageViewModel(theme: theme)

        Observable.just(.badgeImageView(viewModel))
            .bindAndCatch(to: accessoryContentTypeRelay)
            .disposed(by: disposeBag)
    }
}
