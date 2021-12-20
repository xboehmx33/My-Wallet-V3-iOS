// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import NetworkError

extension NetworkError {

    var is404: Bool {
        guard case .rawServerError(let serverError) = self else {
            return false
        }
        guard serverError.response.statusCode == 404 else {
            return false
        }
        return true
    }
}
