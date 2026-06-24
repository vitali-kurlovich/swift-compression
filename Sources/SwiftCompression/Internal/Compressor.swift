//
//  Created by Kurlovich Vitali on 6/24/26.
//

import Compression
import Foundation

struct Compressor {
    func compress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,
        using algorithm: CompressionAlgorithm,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws {
        if let algorithm = algorithm.algorithm {
            try await _compress(read: readFunc,
                                writingTo: writeFunc,
                                algorithm: algorithm,
                                pageSize: pageSize,
                                bufferSize: bufferSize,
                                progressReport: progressReport)
        } else {
            try await _compress(read: readFunc,
                                writingTo: writeFunc,
                                pageSize: pageSize,
                                bufferSize: bufferSize,
                                progressReport: progressReport)
        }
    }
}

private extension Compressor {
    func _compress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,

        algorithm: Algorithm,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void
    ) async throws {
        let outputFilter = try OutputFilter(.compress,
                                            using: algorithm)
        {
            (data: Data?) in
            if let data = data {
                try writeFunc(data)
            }
        }

        var index = 0

        progressReport(bufferSize, index)

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            if rangeLength == 0 {
                break
            }

            let range = index ..< index + rangeLength

            guard let data = try readFunc(range) else {
                assertionFailure()
                break
            }

            try outputFilter.write(data)

            index += rangeLength
            progressReport(bufferSize, index)
        }

        try outputFilter.finalize()

        progressReport(bufferSize, index)
    }

    func _compress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,

        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void
    ) async throws {
        var index = 0

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            if rangeLength == 0 {
                break
            }

            let range = index ..< index + rangeLength

            guard let data = try readFunc(range) else {
                break
            }

            progressReport(bufferSize, index)

            index += rangeLength

            try writeFunc(data)
        }

        progressReport(bufferSize, index)
    }
}
