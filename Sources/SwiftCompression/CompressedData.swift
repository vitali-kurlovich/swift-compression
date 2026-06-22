//
//  Created by Kurlovich Vitali on 6/21/26.
//

import Compression
import Foundation

public extension CompressedData {
    struct Configuration: Hashable, Sendable {
        public let algorithm: CompressionAlgorithm
        public let pageSize: Int
        public let minSizeForSkipCompression: Int

        public init(algorithm: CompressionAlgorithm = .lzma, pageSize: Int = 0, minSizeForSkipCompression: Int = 15) {
            self.algorithm = algorithm
            self.pageSize = pageSize
            self.minSizeForSkipCompression = minSizeForSkipCompression
        }
    }
}

public struct CompressedData: Hashable, Sendable {
    let _data: Data

    public init(data: Data, configuration: Configuration = .init(), progressReport: @escaping (Int, Int) -> Void = { _, _ in }) throws {
        let algorithm: CompressionAlgorithm = configuration.minSizeForSkipCompression >= data.count ? .none : configuration.algorithm
        let pageSize = configuration.pageSize

        let payload = CompressedDataPayload(originalSize: UInt32(data.count), compressedSize: 0, algorithm: algorithm)

        var result = payload.data()

        try result.append(data.compressed(using: algorithm, pageSize: pageSize, progressReport: progressReport))

        _data = result
    }
}

public extension CompressedData {
    init(from data: Data) throws {
        _data = data
    }

    var payload: CompressedDataPayload {
        var size: UInt32 = 0
        var rawValue: UInt8 = CompressionAlgorithm.none.rawValue

        assert(CompressionAlgorithm.none.rawValue == 0)

        let rawSpan = _data.bytes.extracting(first: MemoryLayout.size(ofValue: rawValue))

        rawValue = rawSpan.unsafeLoad(as: type(of: rawValue))

        if rawValue == CompressionAlgorithm.none.rawValue {
            size = .init(_data.count - MemoryLayout.size(ofValue: rawValue))

            return CompressedDataPayload(originalSize: size, compressedSize: size, algorithm: .init(rawValue: rawValue)!)
        }

        let sizeSpan = _data.bytes.extracting(MemoryLayout.size(ofValue: rawValue) ..< MemoryLayout.size(ofValue: rawValue) + MemoryLayout.size(ofValue: size))

        size = .init(bigEndian: sizeSpan.unsafeLoadUnaligned(as: type(of: size)))

        let compressedSize: UInt32 = .init(_data.count - MemoryLayout.size(ofValue: rawValue) - MemoryLayout.size(ofValue: size))

        return CompressedDataPayload(originalSize: size, compressedSize: compressedSize, algorithm: .init(rawValue: rawValue)!)
    }
}

public extension Data {
    init(from: CompressedData) {
        self = from._data
    }
}

extension CompressedData: Codable {
    public enum CodingKeys: String, CodingKey {
        case _data = "data"
    }
}

public extension CompressedData {
    func decompress(pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) throws -> Data {
        let payload = self.payload

        let algorithm = payload.algorithm

        var capacity = MemoryLayout.size(ofValue: algorithm.rawValue)

        if algorithm != .none {
            capacity += MemoryLayout.size(ofValue: payload.originalSize)
        }

        let compresed = _data.subdata(in: capacity ..< _data.count)

        return try compresed.decompressed(using: algorithm,
                                          pageSize: pageSize,
                                          progressReport: progressReport)
    }
}
