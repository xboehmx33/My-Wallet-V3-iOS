// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit
import WalletConnectSwift

/// A RequestHandler that log requests in debug builds.
final class PrintRequestHandler: RequestHandler {
    func canHandle(request: Request) -> Bool {
        #if DEBUG
        print("Request: \(request)")
        #endif
        return false
    }

    func handle(request: Request) {}
}
