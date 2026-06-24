//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Compression
import Foundation

public extension Data {
    func compress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport : @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        if isEmpty {
            return self
        }

        let compressor = Compressor()

        let bufferSize = count

        let pageSize = pageSize == 0 ? bufferSize : pageSize

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

    func decompress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        if isEmpty {
            progressReport(0, 0)
            return self
        }

        guard let algorithm = algorithm.algorithm else {
            progressReport(count, count)
            return self
        }

        let pageSize = pageSize == 0 ? count : pageSize

        var decompressedData = Data()

        var index = 0
        let bufferSize = count

        let inputFilter = try InputFilter(.decompress,
                                          using: algorithm)
        { (length: Int) -> Data? in
            let rangeLength = Swift.min(length, bufferSize - index)
            let subdata = self.subdata(in: index ..< index + rangeLength)
            index += rangeLength

            progressReport(bufferSize, index)

            return subdata
        }

        while let page = try inputFilter.readData(ofLength: pageSize) {
            decompressedData.append(page)
        }

        return decompressedData
    }
}
