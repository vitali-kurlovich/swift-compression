//
//  Created by Kurlovich Vitali on 6/24/26.
//

import Compression
import Foundation

struct Decompressor {
    func decompress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,
        using algorithm: CompressionAlgorithm,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws {
        if let algorithm = algorithm.algorithm {
            try await _decompress(read: readFunc,
                                  writingTo: writeFunc,
                                  using: algorithm,
                                  pageSize: pageSize,
                                  bufferSize: bufferSize,
                                  progressReport: progressReport)
        } else {
            try await _decompress(read: readFunc,
                                  writingTo: writeFunc,
                                  pageSize: pageSize,
                                  bufferSize: bufferSize,
                                  progressReport: progressReport)
        }
    }
}

private extension Decompressor {
    func _decompress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,
        using algorithm: Algorithm,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws {
        var index = 0

        let inputFilter = try InputFilter(.decompress,
                                          using: algorithm)
        { (length: Int) -> Data? in
            let rangeLength = Swift.min(length, bufferSize - index)

            if rangeLength == 0 {
                return nil
            }

            let range = index ..< index + rangeLength

            let subdata = try readFunc(range)

            index += rangeLength

            return subdata
        }

        while let page = try inputFilter.readData(ofLength: pageSize) {
            try writeFunc(page)
            progressReport(bufferSize, index)
        }
    }

    func _decompress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws {
        var index = 0

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)
            let range = index ..< index + rangeLength

            if rangeLength == 0 {
                progressReport(bufferSize, index)
                return
            }

            guard let data = try readFunc(range) else {
                return
            }

            try writeFunc(data)

            progressReport(bufferSize, index)

            index += rangeLength
        }
    }
}
