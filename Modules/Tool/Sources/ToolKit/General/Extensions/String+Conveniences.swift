// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension String {

    // MARK: - Range

    public func range(startingAt index: Int, length: Int) -> Range<String.Index>? {
        let range = NSRange(
            location: index,
            length: length
        )
        return Range(range, in: self)
    }

    public subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    public subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    // MARK: - Validation

    public var isEmail: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return false
        }
        var validated = false
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        detector.enumerateMatches(in: self, range: nsRange) { result, _, _ in
            validated = result?.url?.scheme == "mailto"
        }
        return validated
    }

    public var isAlphanumeric: Bool {
        guard !isEmpty else {
            return false
        }
        guard rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil else {
            return false
        }
        return true
    }

    // MARK: - URL

    /// Returns query arguments from a string in URL format
    public var queryArgs: [String: String] {
        var queryArgs = [String: String]()
        let components = components(separatedBy: "&")
        components.forEach {
            let paramValueArray = $0.components(separatedBy: "=")

            if paramValueArray.count == 2,
               let param = paramValueArray[0].removingPercentEncoding,
               let value = paramValueArray[1].removingPercentEncoding
            {
                queryArgs[param] = value
            }
        }

        return queryArgs
    }

    // MARK: - Other

    public func count(of substring: String) -> Int {
        let components = components(separatedBy: substring)
        return components.count - 1
    }

    /// Removes last char safely
    public mutating func removeLastSafely() {
        guard !isEmpty else { return }
        removeLast()
    }

    public func removing(prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(suffix(count - prefix.count))
    }

    /// Returns the string with no whitespaces
    public var trimmingWhitespaces: String {
        trimmingCharacters(in: .whitespaces)
    }

    /// Returns the base64 string with proper paddings
    public var paddedBase64: String {
        if count % 4 == 0 {
            return self
        } else if (count + 1) % 4 == 0 {
            return self + "="
        } else if (count + 2) % 4 == 0 {
            return self + "=="
        } else {
            // valid base64 (without padding) should require 0-2 paddings only
            return self
        }
    }

    // MARK: - JS

    public func escapedForJS(wrapInQuotes: Bool = false) -> String {
        var output = self
        let insensitive = NSString.CompareOptions.caseInsensitive
        output = output
            .replacingOccurrences(of: "\\", with: "\\\\", options: insensitive) // Reverse solidus
            .replacingOccurrences(of: "\"", with: "\\\"", options: insensitive) // Quotation mark
            .replacingOccurrences(of: "'", with: "\\'", options: insensitive) // Single quote
            .replacingOccurrences(of: "\u{8}", with: "\\b", options: insensitive) // Backspace
            .replacingOccurrences(of: "\u{12}", with: "\\f", options: insensitive) // Formfeed
            .replacingOccurrences(of: "\n", with: "\\n", options: insensitive) // Newline
            .replacingOccurrences(of: "\r", with: "\\r", options: insensitive) // Carriage return
            .replacingOccurrences(of: "\t", with: "\\t", options: insensitive) // Horizontal tab
        return wrapInQuotes ? "\"\(output)\"" : output
    }

    // MARK: - Hex

    /// Returns true if string starts with "0x"
    public var hasHexPrefix: Bool {
        hasPrefix("0x")
    }

    /// Returns string with "0x" prefix (if !isHex)
    public var withHex: String {
        hasHexPrefix ? self : "0x" + self
    }

    /// Returns string without "0x" prefix (if isHex)
    public var withoutHex: String {
        hasHexPrefix ? String(self[index(startIndex, offsetBy: 2)...]) : self
    }

    public var snakeCased: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Adds a separator at every N characters
    /// - Parameters:
    ///   - separator: the String value to be inserted, to separate the groups.
    ///   - stride: the number of characters in the group, before a separator is inserted.
    /// - Returns: Returns a String which includes a `separator` String at every `stride` number of characters.
    public func separatedWithSeparator(
        _ separator: String,
        stride: Int
    ) -> String {
        enumerated()
            .map {
                $0.isMultiple(of: stride) && ($0 != 0) ? "\(separator)\($1)" : String($1)
            }
            .joined()
    }
}
