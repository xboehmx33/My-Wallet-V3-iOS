// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

/// Protocol definition for a URL payload for an asset. The URL typically contains the address,
/// as well as other metadata such as an amount, message, etc. The set of supported metadata
/// can be asset dependent.
public protocol CryptoAssetQRMetadata {
    var cryptoCurrency: CryptoCurrency { get }

    /// The asset's address (e.g. "1Amu4uPJnYbUXX2HhDFMNq7tSneDwWYDyv")
    var address: String { get }

    var amount: String? { get }

    /// Converts this URL to an absolute string (e.g. "bitcoin:1Amu4uPJnYbUXX2HhDFMNq7tSneDwWYDyv")
    var absoluteString: String { get }

    /// Render the `absoluteString` with the scheme prefix
    var includeScheme: Bool { get }
}
