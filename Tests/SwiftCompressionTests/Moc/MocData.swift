//
//  Created by Kurlovich Vitali on 6/22/26.
//

import struct Foundation.Data

enum MocData {
    static var short: Data {
        MocStrings.short.data(using: .utf8)!
    }

    static var medium: Data {
        MocStrings.medium.data(using: .utf8)!
    }

    static var long: Data {
        MocStrings.long.data(using: .utf8)!
    }

    static var array: [Data] {
        MocStrings.strings.map {
            $0.data(using: .utf8)!
        }
    }

    static var joinedArray: Data {
        MocStrings.strings.joined().data(using: .utf8)!
    }
}
