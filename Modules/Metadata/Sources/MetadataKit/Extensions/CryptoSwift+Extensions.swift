// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import CryptoSwift

extension CryptoSwift.AES {

    /// Initialize AES with variant calculated out of key length:
    /// - 16 bytes (AES-128)
    /// - 24 bytes (AES-192)
    /// - 32 bytes (AES-256)
    ///
    /// - parameter key:       Key. Length of the key decides on AES variant.
    /// - parameter iv:        Initialization Vector (Optional for some blockMode values)
    /// - parameter blockMode: Cipher mode of operation
    /// - parameter padding:   Padding method. .pkcs7, .noPadding, .zeroPadding, ...
    ///
    /// - returns: A Result of `Self` or `AES.Error`
    static func create(
        with key: [UInt8],
        blockMode: BlockMode,
        padding: Padding = .pkcs7
    ) -> Result<AES, AES.Error> {
        Result {
            try AES(key: key, blockMode: blockMode, padding: padding)
        }
        .mapError { error -> AES.Error in
            error as! AES.Error
        }
    }
}

extension CryptoSwift.AES {

    /// Encrypt given bytes at once
    ///
    /// - parameter bytes: Plaintext data
    /// - returns: Encrypted data
    func encrypt(bytes: [UInt8]) -> Result<[UInt8], AES.Error> {
        catchToResult(castFailureTo: AES.Error.self) {
            try encrypt(bytes)
        }
    }

    /// Decrypt given bytes at once
    ///
    /// - parameter bytes: Ciphertext data
    /// - returns: Plaintext data
    func decrypt(bytes: [UInt8]) -> Result<[UInt8], AES.Error> {
        catchToResult(castFailureTo: AES.Error.self) {
            try decrypt(bytes)
        }
    }
}
