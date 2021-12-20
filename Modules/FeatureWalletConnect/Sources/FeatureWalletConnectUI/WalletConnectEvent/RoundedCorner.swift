// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

struct RoundedCorner: Shape {

    var cornerRadius: CGFloat
    var corners: UIRectCorner

    init(cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        self.cornerRadius = cornerRadius
        self.corners = corners
    }

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            .cgPath
        )
    }
}
