//
//  Created by Kurlovich Vitali on 6/23/26.
//

import Compression
import Foundation

public extension FileHandle {
    func compress(algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Data {
        let fileHandle: FileHandle = self
        guard let algorithm = algorithm.algorithm else {
            return try await _compress(pageSize: pageSize, progressReport: progressReport)
        }

        return try await _compress(algorithm: algorithm, pageSize: pageSize, progressReport: progressReport)
    }
}

extension FileHandle {
    func _compress(algorithm: Algorithm, pageSize: Int, progressReport: @escaping (Int, Int) -> Void) async throws -> Data {
        let fileHandle: FileHandle = self

        let fileSize = try Int(fileHandle.seekToEnd())
        try fileHandle.seek(toOffset: 0)

        var compressedData = Data()

        let outputFilter = try OutputFilter(.compress,
                                            using: algorithm)
        {
            (data: Data?) in
            if let data = data {
                compressedData.append(data)
            }
        }

        let pageSize = pageSize == 0 ? fileSize : pageSize

        var index = 0
        let bufferSize = fileSize

        progressReport(bufferSize, index)

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            if rangeLength == 0 {
                break
            }

            guard let data = try fileHandle.read(upToCount: rangeLength) else {
                assertionFailure()
                break
            }

            try outputFilter.write(data)

            index += rangeLength
            progressReport(bufferSize, index)
        }

        try outputFilter.finalize()

        progressReport(bufferSize, index)

        return compressedData
    }

    func _compress(pageSize: Int, progressReport: @escaping (Int, Int) -> Void) async throws -> Data {
        let fileHandle: FileHandle = self

        let fileSize = try Int(fileHandle.seekToEnd())
        try fileHandle.seek(toOffset: 0)

        var compressedData = Data(capacity: fileSize)

        let pageSize = pageSize == 0 ? fileSize : pageSize

        var index = 0
        let bufferSize = fileSize

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            if rangeLength == 0 {
                break
            }

            guard let data = try fileHandle.read(upToCount: rangeLength) else {
                break
            }

            progressReport(bufferSize, index)

            index += rangeLength

            compressedData.append(data)
        }

        progressReport(bufferSize, index)

        return compressedData
    }
}
