//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Foundation
@testable import SwiftCompression
import Testing

struct DataTest {
    @Test(arguments: CompressedData.Configuration.all)
    func decompress(_ configuration: CompressedData.Configuration) throws {
        let data = MocData.long
        let compressed = try data.compressed(using: configuration.algorithm, pageSize: configuration.pageSize)

        if configuration.algorithm == .none {
            #expect(compressed == data)
        } else {
            #expect(compressed != data)
        }

        let uncompress = try compressed.decompressed(using: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(uncompress == data)
    }
}
