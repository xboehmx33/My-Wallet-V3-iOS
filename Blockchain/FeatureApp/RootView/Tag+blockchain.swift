//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable type_name

let blockchain = Tag_blockchain("blockchain")

class Tag_blockchain: Tag {
    var ux: Tag_blockchain_ux { child() }
}

class Tag_blockchain_ux: Tag {
    var user: Tag_blockchain_ux_user { child() }
}

class Tag_blockchain_ux_user: Tag {
    var account: Tag { child() }
    var activity: Tag { child() }
    var buy_and_sell: Tag { child() }
    var fab: Tag_blockchain_ux_user_fab { child() }
    var portfolio: Tag { child() }
    var prices: Tag { child() }
    var scan: Tag_blockchain_ux_user_scan { child() }
}

class Tag_blockchain_ux_user_fab: Tag {
    var buy: Tag { child() }
    var deposit: Tag { child() }
    var receive: Tag { child() }
    var rewards: Tag { child() }
    var sell: Tag { child() }
    var send: Tag { child() }
    var swap: Tag { child() }
    var withdraw: Tag { child() }
}

class Tag_blockchain_ux_user_scan: Tag {
    var qr: Tag { child() }
}

extension Tag {

    fileprivate func child<T>(_ name: String = #function) -> T where T: Tag {
        T("\(_id).\(name)")
    }
}
