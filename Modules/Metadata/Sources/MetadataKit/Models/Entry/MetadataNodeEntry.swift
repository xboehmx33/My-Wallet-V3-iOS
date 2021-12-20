// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public protocol MetadataNodeEntry: Codable {

    static var type: EntryType { get }
}
