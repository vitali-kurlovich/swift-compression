//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Compression
import Foundation

public extension Data {
    func compress(writingTo writeFunc: @escaping (Data) throws -> Void,
                  using algorithm: CompressionAlgorithm,
                  pageSize: Int = 0,
                  progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws
    {
        if isEmpty {
            progressReport(count, count)
            return
        }

        let bufferSize = count
        let pageSize = pageSize == 0 ? bufferSize : pageSize

        let compressor = Compressor()

        try await compressor.compress(read: { range in
            self.subdata(in: range)
        }, writingTo: writeFunc,
        using: algorithm, pageSize: pageSize,
        bufferSize: bufferSize,
        progressReport: progressReport)
    }
}

public extension Data {
    func compress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        var compressedData = Data()
        try await compress(writingTo: { data in
            compressedData.append(data)
        }, using: algorithm,
        pageSize: pageSize,
        progressReport: progressReport)

        return compressedData
    }

    func compress(writeTo output: FileHandle, using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws {
        try await compress(writingTo: { data in
            try output.write(contentsOf: data)
        }, using: algorithm,
        pageSize: pageSize,
        progressReport: progressReport)
    }
}

public extension Data {
    func decompress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        if isEmpty || algorithm == .none {
            progressReport(count, count)
            return self
        }

        let bufferSize = count
        let pageSize = pageSize == 0 ? bufferSize : pageSize

        let decompressor = Decompressor()

        var decompressedData = Data()

        try await decompressor.decompress(read: { range in
            self.subdata(in: range)
        }, writingTo: { data in
            decompressedData.append(data)
        }, using: algorithm,
        pageSize: pageSize,
        bufferSize: bufferSize,
        progressReport: progressReport)

        return decompressedData
    }
}
