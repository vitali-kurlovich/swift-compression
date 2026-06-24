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

    public init(data: Data, configuration: Configuration = .init(), progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws {
        let algorithm: CompressionAlgorithm = configuration.minSizeForSkipCompression >= data.count ? .none : configuration.algorithm
        let pageSize = configuration.pageSize

        let payload = CompressedDataPayload(originalSize: UInt32(data.count), compressedSize: 0, algorithm: algorithm)

        var result = payload.data()

        let compressed = try await data.compress(using: algorithm, pageSize: pageSize, progressReport: progressReport)

        result.append(compressed)

        _data = result
    }
}

public extension CompressedData {
    init(from data: Data) throws {
        _data = data
    }

    var payload: CompressedDataPayload {
        var rawValue: UInt8 = CompressionAlgorithm.none.rawValue

        var size: UInt32 = 0

        _data.withUnsafeBytes { pointer in
            rawValue = pointer.load(as: type(of: rawValue))

            if rawValue == CompressionAlgorithm.none.rawValue {
                size = .init(_data.count - MemoryLayout.size(ofValue: rawValue))
            } else {
                size = .init(bigEndian: pointer.loadUnaligned(fromByteOffset: MemoryLayout.size(ofValue: rawValue), as: type(of: size)))
            }
        }

        let algorithm = CompressionAlgorithm(rawValue: rawValue)!

        let compressedSize: UInt32

        if algorithm == .none {
            compressedSize = .init(_data.count - MemoryLayout.size(ofValue: rawValue))
        } else {
            compressedSize = .init(_data.count - MemoryLayout.size(ofValue: rawValue) - MemoryLayout.size(ofValue: size))
        }

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
    func decompress(pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Data {
        let payload = self.payload

        let algorithm = payload.algorithm

        var capacity = MemoryLayout.size(ofValue: algorithm.rawValue)

        if algorithm != .none {
            capacity += MemoryLayout.size(ofValue: payload.originalSize)
        }

        let startIndex = _data.index(_data.startIndex, offsetBy: capacity)
        let endIndex = _data.endIndex

        let compresed = _data.subdata(in: startIndex ..< endIndex)

        return try await compresed.decompress(using: algorithm,
                                              pageSize: pageSize,
                                              progressReport: progressReport)
    }
}
