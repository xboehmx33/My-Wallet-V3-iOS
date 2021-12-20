// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SnapshotTesting
import XCTest

final class IconButtonTexts: XCTestCase {

    let button = IconButton(icon: .qrCode) {}

    func testDefault() {
        assertSnapshot(matching: button, as: .image)
    }

    func testDisabled() {
        assertSnapshot(matching: button.disabled(true), as: .image)
    }

    func testCircle() {
        let button = IconButton(icon: .qrCode.circle()) {}.frame(width: 32, height: 32)
        assertSnapshot(matching: button, as: .image)
    }
}
