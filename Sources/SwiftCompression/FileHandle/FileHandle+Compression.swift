//
//  Created by Kurlovich Vitali on 6/23/26.
//

import Compression
import Foundation

public extension FileHandle {
    func compress(algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport _: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Data {
        let fileHandle: FileHandle = self

        let fileSize = try Int(fileHandle.seekToEnd())
        try fileHandle.seek(toOffset: 0)

        let compressor = Compressor()

        let bufferSize = fileSize

        let pageSize = pageSize == 0 ? bufferSize : pageSize

        var compressedData = Data()

        try await compressor.compress(read: { range in
            try fileHandle.read(upToCount: range.count)
        }, writingTo: { data in
            compressedData.append(data)
        }, algorithm: algorithm, pageSize: pageSize, bufferSize: bufferSize)

        return compressedData
    }
}
