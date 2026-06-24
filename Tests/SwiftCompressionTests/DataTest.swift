//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Foundation
@testable import SwiftCompression
import Testing

struct DataTest {
    @Test(arguments: CompressedData.Configuration.all)
    func decompress(_ configuration: CompressedData.Configuration) async throws {
        let data = MocData.long
        let compressed = try await data.compress(using: configuration.algorithm, pageSize: configuration.pageSize)

        if configuration.algorithm == .none {
            #expect(compressed == data)
        } else {
            #expect(compressed != data)
        }

        let uncompress = try await compressed.decompress(using: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(uncompress == data)
    }
}
