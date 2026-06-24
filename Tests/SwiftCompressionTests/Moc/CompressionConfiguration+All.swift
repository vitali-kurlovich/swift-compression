//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Foundation
import SwiftCompression

extension CompressedData.Configuration {
    static var all: [CompressedData.Configuration] {
        [0, 8, 128, 1024, 4096].map { pageSize in
            CompressionAlgorithm.allCases.map {
                CompressedData.Configuration(algorithm: $0, pageSize: pageSize, minSizeForSkipCompression: 16)
            }
        }.flatMap {
            $0
        }
    }
}
