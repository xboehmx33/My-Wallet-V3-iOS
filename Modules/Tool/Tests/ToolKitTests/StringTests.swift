// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ToolKit
import XCTest

class StringTests: XCTestCase {

    func testPaddedBase64() throws {
        let pairs: [(testcase: String, result: String)] = [
            // two paddings required
            (
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ",
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ=="
            ),

            // one padding required
            (
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ=",
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ=="
            ),

            // no paddings required
            (
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ==",
                // swiftlint:disable line_length
                "eyJndWlkIjoiZjEyY2M1MDctNTdmMC00ZDYxLTkwNzQtYTU3YTA2ZTJmYTQ0IiwiZW1haWwiOiJncmF5c29uQGJsb2NrY2hhaW4uY29tIiwiaXNfbW9iaWxlX3NldHVwIjpmYWxzZSwiaGFzX2Nsb3VkX2JhY2t1cCI6ZmFsc2UsImVtYWlsX2NvZGUiOiJiYnV1OFRweHRodWhQRi9KdXJNMGJYYXZ6Slo0UWd4aHZ1MUNxV1V0YllOUW1RNEpGY3N0OWtZOWNjR25oYlpVM3N2cW5TQjFOcjhPOElIMFhrWWU1OFdzYU5RelhSL2ZlS015NmE1VXdFdjE0LzBoM1Z6UCtvc1dJU3ZBSldkUko4Y0pObXFuUTcxWFh0ajE3RjRtSXNYVklNalc2L0V0Mm1NWWdOQTJqZlRwaDY0MXlTTHEzb2RRQ3FGY2hHcEgifQ=="
            )
        ]
        for pair in pairs {
            XCTAssertEqual(pair.testcase.paddedBase64, pair.result)
        }
    }

    func testHasHex() throws {
        let pairs: [(testcase: String, result: Bool)] = [
            //
            ("0x0x", true),
            ("0x", true),
            ("0x1", true),
            ("0xa", true),

            //
            (" 0x", false),
            ("00x", false),
            ("a0x1", false),
            ("a0xa", false)
        ]
        for pair in pairs {
            XCTAssertEqual(pair.testcase.hasHexPrefix, pair.result)
        }
    }

    func testWithHex() throws {
        let pairs: [(testcase: String, result: String)] = [
            //
            ("0x", "0x"),
            ("0xa", "0xa"),
            ("0x1", "0x1"),

            //
            ("", "0x"),
            (" ", "0x "),
            (" 0x", "0x 0x"),
            ("a", "0xa"),
            ("1", "0x1"),
            ("x", "0xx"),
            ("0", "0x0")
        ]
        for pair in pairs {
            XCTAssertEqual(pair.testcase.withHex, pair.result)
        }
    }

    func testWithoutHex() throws {
        let pairs: [(testcase: String, result: String)] = [
            //
            ("0x", ""),
            ("0xa", "a"),
            ("0x1", "1"),

            //
            ("", ""),
            (" ", " "),
            (" 0x", " 0x"),
            ("a", "a"),
            ("1", "1"),
            ("x", "x"),
            ("0", "0")
        ]
        for pair in pairs {
            XCTAssertEqual(pair.testcase.withoutHex, pair.result)
        }
    }

    func testIbanFormatting() throws {
        let iban = "EE707777000013197360"
        let formatted = iban.separatedWithSeparator(" ", stride: 4)
        XCTAssertEqual("EE70 7777 0000 1319 7360", formatted)
    }

    func testEmptyIban() throws {
        let iban = ""
        let formatted = iban.separatedWithSeparator(" ", stride: 4)
        XCTAssertEqual("", formatted)
    }
}
