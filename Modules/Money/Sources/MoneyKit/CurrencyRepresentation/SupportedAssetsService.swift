// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation
import ToolKit

/// Fetches supported assets from the app bundle.
protocol SupportedAssetsServiceAPI {
    var erc20Assets: Result<SupportedAssetsResponse, SupportedAssetsLocalError> { get }
    var custodialAssets: Result<SupportedAssetsResponse, SupportedAssetsLocalError> { get }
}

enum SupportedAssetsLocalError: Error {
    case unimplemented
    case missingLocalFile
    case missingRemoteFile
    case decodingFailed(Error)
}

final class SupportedAssetsService: SupportedAssetsServiceAPI {

    var erc20Assets: Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        switch remoteERC20Assets() {
        case .success(let response):
            return .success(response)
        case .failure:
            return bundleERC20Assets()
        }
    }

    var custodialAssets: Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        switch remoteCustodialAssets() {
        case .success(let response):
            return .success(response)
        case .failure:
            return bundleCustodialAssets()
        }
    }

    private let errorLogger: ErrorRecording
    private let filePathProvider: SupportedAssetsFilePathProviderAPI
    private let jsonDecoder: JSONDecoder

    init(
        errorLogger: ErrorRecording = resolve(),
        filePathProvider: SupportedAssetsFilePathProviderAPI = resolve(),
        jsonDecoder: JSONDecoder = .init()
    ) {
        self.errorLogger = errorLogger
        self.filePathProvider = filePathProvider
        self.jsonDecoder = jsonDecoder
    }

    /// Loads the most recently downloaded ERC20 currencies list file.
    private func remoteERC20Assets() -> Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        guard let fileURL = filePathProvider.remoteERC20Assets else {
            return .failure(.missingRemoteFile)
        }
        return load(fileURL: fileURL)
    }

    /// Loads the ERC20 currencies list file shipped within the Bundle.
    private func bundleERC20Assets() -> Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        guard let fileURL = filePathProvider.localERC20Assets else {
            return .failure(.missingLocalFile)
        }
        return load(fileURL: fileURL)
    }

    /// Loads the most recently downloaded Custodial currencies list file.
    private func remoteCustodialAssets() -> Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        guard let fileURL = filePathProvider.remoteCustodialAssets else {
            return .failure(.missingRemoteFile)
        }
        return load(fileURL: fileURL)
    }

    /// Loads the Custodial currencies list file shipped within the Bundle.
    private func bundleCustodialAssets() -> Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        guard let fileURL = filePathProvider.localCustodialAssets else {
            return .failure(.missingLocalFile)
        }
        return load(fileURL: fileURL)
    }

    private func load(fileURL: URL) -> Result<SupportedAssetsResponse, SupportedAssetsLocalError> {
        do {
            let data = try Data(contentsOf: fileURL, options: .uncached)
            let response = try jsonDecoder.decode(SupportedAssetsResponse.self, from: data)
            return .success(response)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }
}
