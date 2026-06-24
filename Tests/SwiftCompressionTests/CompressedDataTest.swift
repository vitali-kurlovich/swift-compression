//
//  Created by Kurlovich Vitali on 6/21/26.
//

import Foundation
import SwiftCompression
import Testing

struct CompressedDataTest {
    @Test(arguments: DataPresset.all)
    func decompress(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        let compressed = try await CompressedData(data: data, configuration: configuration)

        if configuration.minSizeForSkipCompression < data.count {
            #expect(compressed.payload.algorithm == configuration.algorithm)
        } else {
            #expect(compressed.payload.algorithm == .none)
        }

        #expect(compressed.payload.originalSize == data.count)

        let uncompress = try await compressed.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: DataPresset.all)
    func json(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        let compressed = try await CompressedData(data: data, configuration: configuration)

        let encoder = JSONEncoder()
        let json = try encoder.encode(compressed)

        let decoder = JSONDecoder()

        let decoded = try decoder.decode(CompressedData.self, from: json)

        if configuration.minSizeForSkipCompression < data.count {
            #expect(compressed.payload.algorithm == configuration.algorithm)
        } else {
            #expect(compressed.payload.algorithm == .none)
        }
        #expect(decoded.payload.originalSize == data.count)

        let uncompress = try await decoded.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: [
        MocMediumCompressedData.none,
        MocMediumCompressedData.lz4,
        MocMediumCompressedData.lzma,
        MocMediumCompressedData.zlib,
        MocMediumCompressedData.brotli,
    ])
    func fromMediumData(_ data: Data) async throws {
        let originalData = MocData.medium

        let compressed = try CompressedData(from: data)
        #expect(compressed.payload.originalSize == originalData.count)

        let uncompress = try await compressed.decompress()

        #expect(uncompress == originalData)
    }
}
