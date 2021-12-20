// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import NetworkKit
import PlatformKit
import RxSwift
import ToolKit

enum ExchangeLinkingAPIError: Error {
    case noLinkID
    case unknown
}

protocol ExchangeAccountAuthenticatorAPI {
    typealias LinkID = String

    var exchangeLinkID: Single<LinkID> { get }
    var exchangeURL: Single<URL> { get }

    func linkToExistingExchangeUser(linkID: LinkID) -> Completable
}

class ExchangeAccountAuthenticator: ExchangeAccountAuthenticatorAPI {

    private let dataRepository: DataRepositoryAPI
    private let client: ExchangeClientAPI
    private let campaignComposer: CampaignComposer

    init(
        dataRepository: DataRepositoryAPI = resolve(),
        campaignComposer: CampaignComposer = CampaignComposer(),
        client: ExchangeClientAPI = resolve()
    ) {
        self.dataRepository = dataRepository
        self.campaignComposer = campaignComposer
        self.client = client
    }

    var exchangeLinkID: Single<LinkID> {
        client.linkID.asSingle()
    }

    var exchangeURL: Single<URL> {
        Single
            .zip(
                dataRepository.user.asSingle(),
                exchangeLinkID
            )
            .flatMap(weak: self) { (self, payload) -> Single<URL> in
                let (user, linkID) = payload

                let email = self.percentEscapeString(user.email.address)
                guard let apiURL = URL(string: BlockchainAPI.shared.exchangeURL) else {
                    return Single.error(ExchangeLinkingAPIError.unknown)
                }

                let pathComponents = ["trade", "link", linkID]
                var queryParams = Dictionary(
                    uniqueKeysWithValues: self.campaignComposer.generalQueryValuePairs
                        .map { ($0.rawValue, $1.rawValue) }
                )
                queryParams += ["email": email]

                guard let endpoint = URL.endpoint(apiURL, pathComponents: pathComponents, queryParameters: queryParams) else {
                    return Single.error(ExchangeLinkingAPIError.unknown)
                }

                return Single.just(endpoint)
            }
    }

    func linkToExistingExchangeUser(linkID: LinkID) -> Completable {
        client.linkToExistingExchangeUser(linkID: linkID)
            .asObservable()
            .ignoreElements()
            .asCompletable()
    }

    private func percentEscapeString(_ stringToEscape: String) -> String {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-._* ")
        return stringToEscape
            .addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)?
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil) ?? stringToEscape
    }
}
