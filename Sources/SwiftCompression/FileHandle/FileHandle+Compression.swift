//
//  Created by Kurlovich Vitali on 6/23/26.
//

import Compression
import Foundation

public extension FileHandle {
    func compress(writingTo writeFunc: @escaping (Data) throws -> Void,
                  using algorithm: CompressionAlgorithm,
                  pageSize: Int = 0,
                  progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws
    {
        let fileHandle: FileHandle = self

        let fileSize = try Int(fileHandle.seekToEnd())
        try fileHandle.seek(toOffset: 0)

        if fileSize == 0 {
            return
        }

        let compressor = Compressor()

        let bufferSize = fileSize

        let pageSize = pageSize == 0 ? bufferSize : pageSize

        try await compressor.compress(read: { range in
            try fileHandle.read(upToCount: range.count)
        }, writingTo: writeFunc,
        using: algorithm,
        pageSize: pageSize,
        bufferSize: bufferSize,
        progressReport: progressReport)
    }

    func compress(writeTo output: FileHandle, using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws {
        try await compress(writingTo: { data in
                               try output.write(contentsOf: data)
                           },
                           using: algorithm,
                           pageSize: pageSize,
                           progressReport: progressReport)
    }

    func compress(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Data {
        var compressedData = Data()

        try await compress(writingTo: { data in
                               compressedData.append(data)
                           },
                           using: algorithm,
                           pageSize: pageSize,
                           progressReport: progressReport)

        return compressedData
    }
}

public extension FileHandle {
    func decompress(algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> Data {
        let fileHandle: FileHandle = self

        let fileSize = try Int(fileHandle.seekToEnd())
        try fileHandle.seek(toOffset: 0)

        if fileSize == 0 {
            return Data()
        }

        if algorithm == .none {
            return try fileHandle.read(upToCount: fileSize) ?? Data()
        }

        let bufferSize = fileSize
        let pageSize = pageSize == 0 ? bufferSize : pageSize

        let decompressor = Decompressor()

        var decompressedData = Data()

        try await decompressor.decompress(read: { range in
            try fileHandle.read(upToCount: range.count)
        }, writingTo: { data in
            decompressedData.append(data)
        }, using: algorithm,
        pageSize: pageSize,
        bufferSize: bufferSize,
        progressReport: progressReport)

        return decompressedData
    }
}
