// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import StoreKit
import ToolKit

public enum StoreReviewController {

    public static func requestReview() {
        #if !DEBUG
        let disableRating = ProcessInfo.processInfo
            .environmentBoolean(for: .disableRatingPrompt) ?? false
        guard !disableRating else {
            Logger.shared.debug("Store Review disable due to automation_disable_rating_prompt.")
            return
        }
        SKStoreReviewController.requestReviewInCurrentScene()
        #endif
    }
}

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        if let scene = UIApplication.shared.connectedScenes.first(
            where: { $0.activationState == .foregroundActive }
        ) as? UIWindowScene {
            requestReview(in: scene)
        }
    }
}
