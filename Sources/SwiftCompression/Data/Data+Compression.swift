//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Compression
import Foundation

public extension Data {
    func compress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        if isEmpty || algorithm == .none {
            progressReport(count, count)
            return self
        }

        let bufferSize = count
        let pageSize = pageSize == 0 ? bufferSize : pageSize

        let compressor = Compressor()

        var compressedData = Data()

        try await compressor.compress(read: { range in
            self.subdata(in: range)
        }, writingTo: { data in
            compressedData.append(data)
        }, algorithm: algorithm, pageSize: pageSize,
        bufferSize: bufferSize,
        progressReport: progressReport)

        return compressedData
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
