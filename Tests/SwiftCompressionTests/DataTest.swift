//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Foundation
@testable import SwiftCompression
import Testing

struct DataTest {
    @Test(arguments: DataPresset.all)
    func decompress(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        let compressed = try await data.compress(using: configuration.algorithm, pageSize: configuration.pageSize)

        if configuration.algorithm == .none {
            #expect(compressed == data)
        } else {
            if data.isEmpty {
                #expect(compressed.isEmpty)
            } else {
                #expect(compressed != data)
            }
        }

        let uncompress = try await compressed.decompress(using: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(uncompress == data)
    }
}
