//
//  Created by Kurlovich Vitali on 6/21/26.
//

import Foundation
import SwiftCompression
import Testing

struct CompressedDataTest {
    @Test(arguments: CompressedData.Configuration.all)
    func decompress(_ configuration: CompressedData.Configuration) throws {
        let data = MocData.long

        let compressed = try CompressedData(data: data, configuration: configuration)

        #expect(compressed.payload.algorithm == configuration.algorithm)
        #expect(compressed.payload.originalSize == data.count)

        let uncompress = try compressed.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: CompressedData.Configuration.all)
    func decompressSmall(_ configuration: CompressedData.Configuration) throws {
        let data = MocData.short

        let compressed = try CompressedData(data: data, configuration: configuration)

        #expect(compressed.payload.algorithm == .none)
        #expect(compressed.payload.originalSize == data.count)
        #expect(compressed.payload.compressedSize == data.count)

        let uncompress = try compressed.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: CompressedData.Configuration.all)
    func json(_ configuration: CompressedData.Configuration) throws {
        let data = MocData.long

        let compressed = try CompressedData(data: data, configuration: configuration)

        let encoder = JSONEncoder()
        let json = try encoder.encode(compressed)

        let decoder = JSONDecoder()

        let decoded = try decoder.decode(CompressedData.self, from: json)

        #expect(decoded.payload.algorithm == configuration.algorithm)
        #expect(decoded.payload.originalSize == data.count)

        let uncompress = try decoded.decompress()

        #expect(uncompress == data)
    }

    @Test(arguments: [CompressionAlgorithm.brotli])
    func prepare(_ algorithm: CompressionAlgorithm) throws {
        let data = MocData.medium
        let configuration = CompressedData.Configuration(algorithm: algorithm, pageSize: 0)

        let compressed = try Data(from: CompressedData(data: data, configuration: configuration))

        let str = compressed.map {
            "0x" + String($0, radix: 16)
        }.joined(separator: ",")

        debugPrint("static var \(algorithm): Data { Data( [\(str)] )}")
    }

    @Test(arguments: [
        MocMediumCompressedData.none,
        MocMediumCompressedData.lz4,
        MocMediumCompressedData.lzma,
        MocMediumCompressedData.zlib,
        MocMediumCompressedData.brotli,
    ])
    func fromMediumData(_ data: Data) throws {
        let originalData = MocData.medium

        let compressed = try CompressedData(from: data)
        #expect(compressed.payload.originalSize == originalData.count)

        let uncompress = try compressed.decompress()

        #expect(uncompress == originalData)
    }
}
