@testable import ComponentLibrary
import SnapshotTesting
import SwiftUI
import XCTest

final class PrimaryRowTests: XCTestCase {

    func testSnapshot() {
        let view = VStack(spacing: 0) {
            PrimaryRow_Previews.previews
        }
        .fixedSize()

        assertSnapshots(
            matching: view,
            as: [
                .image(layout: .sizeThatFits, traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(layout: .sizeThatFits, traits: UITraitCollection(userInterfaceStyle: .dark))
            ]
        )
    }
}
