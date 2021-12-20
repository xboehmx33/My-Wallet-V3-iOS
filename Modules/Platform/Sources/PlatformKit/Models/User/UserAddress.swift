// Copyright © Blockchain Luxembourg S.A. All rights reserved.

// TICKET: IOS-1145 - Combine PostalAddress and UserAddress models.
public struct UserAddress {

    public let lineOne: String?
    public let lineTwo: String?
    public let postalCode: String?
    public let city: String?
    public let state: String?
    public let countryCode: String

    public var country: Country {
        Country(code: countryCode)!
    }

    public init(
        lineOne: String?,
        lineTwo: String?,
        postalCode: String?,
        city: String?,
        state: String?,
        countryCode: String
    ) {
        self.lineOne = lineOne
        self.lineTwo = lineTwo
        self.postalCode = postalCode
        self.city = city
        self.state = state
        self.countryCode = countryCode
    }
}

extension UserAddress: Equatable {

    public static func == (lhs: UserAddress, rhs: UserAddress) -> Bool {
        lhs.lineOne == rhs.lineOne &&
            lhs.lineTwo == rhs.lineTwo &&
            lhs.postalCode == rhs.postalCode &&
            lhs.city == rhs.city &&
            lhs.countryCode == rhs.countryCode &&
            lhs.state == rhs.state
    }
}

extension UserAddress: Codable {

    public enum CodingKeys: String, CodingKey {
        case lineOne = "line1"
        case lineTwo = "line2"
        case postalCode = "postCode"
        case city
        case state
        case countryCode = "country"
    }
}

extension UserAddress: Hashable {}
