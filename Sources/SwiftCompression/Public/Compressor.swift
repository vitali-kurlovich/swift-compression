//
//  Created by Kurlovich Vitali on 6/24/26.
//

#if os(anyAppleOS)
    import Compression
#elseif os(Linux)
    import Lzma
#endif

import struct Foundation.Data

public struct Compressor {
    public init() {}
}

public extension Compressor {
    func compress(
        read readFunc: @escaping (Range<Int>) throws -> Data?,
        writingTo writeFunc: @escaping (Data) throws -> Void,
        using algorithm: CompressionAlgorithm,
        pageSize: Int,
        bufferSize: Int,
        progressReport: @escaping (Int, Int) -> Void = { _, _ in }
    ) async throws {
        #if os(anyAppleOS)

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
        #elseif os(Linux)
            if algorithm == .lzma {
                let encoder = LzmaEncoder(progress: { total, progress in
                    progressReport(total, min(total, progress))
                }) {
                    Task.isCancelled
                }

                var position = 0

                try encoder.encode(read: { length in
                    let range = position ..< (position + length)
                    position += length

                    return try readFunc(range)

                }, write: writeFunc)
            } else {
                assert(algorithm == .none)
                try await _compress(read: readFunc,
                                    writingTo: writeFunc,
                                    pageSize: pageSize,
                                    bufferSize: bufferSize,
                                    progressReport: progressReport)
            }
        #endif
    }
}

private extension Compressor {
    #if os(anyAppleOS)

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

    #endif

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
