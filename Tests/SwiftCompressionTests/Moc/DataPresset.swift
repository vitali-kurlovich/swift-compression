//
//  Created by Kurlovich Vitali on 6/24/26.
//

import Foundation
import SwiftCompression

struct DataPresset {
    let configuration: CompressedData.Configuration
    let data: Data
}

extension DataPresset {
    static var all: [Self] {
        let configurations = CompressedData.Configuration.all

        var dataCollection: [Data] = [Data()]
        dataCollection.append(contentsOf: MocData.array)
        dataCollection.append(MocData.joinedArray)

        var pressets: [Self] = []

        for configuration in configurations {
            for data in dataCollection {
                let presset = DataPresset(configuration: configuration, data: data)
                pressets.append(presset)

                let pageSize = configuration.pageSize

                let pageData = Data(repeating: 0x47, count: pageSize)

                pressets.append(DataPresset(configuration: configuration, data: pageData))
            }
        }

        return pressets
    }
}
