// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
@testable import MoneyKit
@testable import PlatformKit
import XCTest

@testable import MoneyKitMock
@testable import PlatformKitMock
@testable import ToolKitMock

final class SupportedAssetsServiceTests: XCTestCase {

    var fileProviderMock: SupportedAssetsLocalFilePathProviderMock!
    var sut: SupportedAssetsServiceAPI!

    override func setUp() {
        super.setUp()
        fileProviderMock = SupportedAssetsLocalFilePathProviderMock()
        sut = SupportedAssetsService(errorLogger: MockErrorRecorder(), filePathProvider: fileProviderMock)
    }

    override func tearDown() {
        super.tearDown()
        fileProviderMock = nil
        sut = nil
    }

    func testDecodesFromRemoteFile() {
        fileProviderMock.remoteERC20Assets = createValidFile()
        XCTAssertNoThrow(try sut.erc20Assets.get())
    }

    func testDecodesFromLocalFileIfRemoteMissing() {
        fileProviderMock.localERC20Assets = createValidFile()
        XCTAssertNoThrow(try sut.erc20Assets.get())
    }

    func testDecodesFromLocalFileIfRemoteMalformed() {
        fileProviderMock.remoteERC20Assets = createEmptyFile()
        fileProviderMock.localERC20Assets = createValidFile()
        XCTAssertNoThrow(try sut.erc20Assets.get())
    }

    func testThrowsIfRemoteMalformedAndLocalIsMalformed() {
        fileProviderMock.remoteERC20Assets = createEmptyFile()
        fileProviderMock.localERC20Assets = createEmptyFile()
        XCTAssertThrowsError(try sut.erc20Assets.get()) { error in
            switch error {
            case SupportedAssetsLocalError.decodingFailed:
                break
            default:
                XCTFail("Got \(error)")
            }
        }
    }

    func testThrowsIfRemoteMissingAndLocalIsMalformed() {
        fileProviderMock.localERC20Assets = createEmptyFile()
        XCTAssertThrowsError(try sut.erc20Assets.get()) { error in
            switch error {
            case SupportedAssetsLocalError.decodingFailed:
                break
            default:
                XCTFail("Got \(error)")
            }
        }
    }

    func testThrowsIfRemoteAndLocalAreMissing() {
        XCTAssertThrowsError(try sut.erc20Assets.get()) { error in
            switch error {
            case SupportedAssetsLocalError.missingLocalFile:
                break
            default:
                XCTFail("Got \(error)")
            }
        }
    }

    private func createValidFile() -> URL {
        let dirPath = NSTemporaryDirectory()
        let uuid = UUID().uuidString
        let filePath = "\(dirPath)/\(uuid).json"
        FileManager.default.createFile(
            atPath: filePath,
            contents: "{\"currencies\":[]}".data(using: .utf8)
        )
        return URL(fileURLWithPath: filePath)
    }

    private func createEmptyFile() -> URL {
        let dirPath = NSTemporaryDirectory()
        let uuid = UUID().uuidString
        let filePath = "\(dirPath)/\(uuid).json"
        FileManager.default.createFile(
            atPath: filePath,
            contents: "".data(using: .utf8)
        )
        return URL(string: filePath)!
    }
}
