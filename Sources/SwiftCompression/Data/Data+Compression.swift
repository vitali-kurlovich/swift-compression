//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Compression
import Foundation

public extension Data {
    func compressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        assert(isEmpty == false)

        guard let algorithm = algorithm.algorithm else {
            progressReport(count, count)

            return self
        }

        let pageSize = pageSize == 0 ? count : pageSize

        var compressedData = Data()

        let outputFilter = try OutputFilter(.compress,
                                            using: algorithm)
        {
            (data: Data?) in
            if let data = data {
                compressedData.append(data)
            }
        }

        var index = 0
        let bufferSize = count

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            let subdata = self.subdata(in: index ..< index + rangeLength)
            index += rangeLength

            try outputFilter.write(subdata)

            if rangeLength == 0 {
                break
            }

            progressReport(count, index)
        }

        try outputFilter.finalize()

        return compressedData
    }

    func decompressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Self {
        assert(isEmpty == false)

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
