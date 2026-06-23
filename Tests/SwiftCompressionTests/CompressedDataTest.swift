//
//  Created by Kurlovich Vitali on 6/21/26.
//

import Foundation
import SwiftCompression
import Testing

struct CompressedDataTest {
    @Test(arguments: CompressedData.Configuration.all)
    func decompress(_ configuration: CompressedData.Configuration) async throws {
        let data = MocData.long

        let compressed = try await CompressedData(data: data, configuration: configuration)

        #expect(compressed.payload.algorithm == configuration.algorithm)
        #expect(compressed.payload.originalSize == data.count)

        let uncompress = try await compressed.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: CompressedData.Configuration.all)
    func decompressSmall(_ configuration: CompressedData.Configuration) async throws {
        let data = MocData.short

        let compressed = try await CompressedData(data: data, configuration: configuration)

        #expect(compressed.payload.algorithm == .none)
        #expect(compressed.payload.originalSize == data.count)
        #expect(compressed.payload.compressedSize == data.count)

        let uncompress = try await compressed.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: CompressedData.Configuration.all)
    func json(_ configuration: CompressedData.Configuration) async throws {
        let data = MocData.long

        let compressed = try await CompressedData(data: data, configuration: configuration)

        let encoder = JSONEncoder()
        let json = try encoder.encode(compressed)

        let decoder = JSONDecoder()

        let decoded = try decoder.decode(CompressedData.self, from: json)

        #expect(decoded.payload.algorithm == configuration.algorithm)
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
