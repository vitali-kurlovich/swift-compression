//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Compression
import Foundation

public extension Data {
    func compressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: (Int, Int) -> Void = { _, _ in }) throws -> Self {
        if #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) {
            return try _compressed(using: algorithm, pageSize: pageSize, progressReport: progressReport)
        }

        guard let algorithm = algorithm.compression_algorithm else {
            progressReport(count, count)
            return self
        }

        return try compressWithBuffer(algorithm: algorithm, progressReport: progressReport)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func decompressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) throws -> Self {
        try _decompressed(using: algorithm, pageSize: pageSize, progressReport: progressReport)
    }

    func decompressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, uncompressedSize: Int, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) throws -> Self {
        if #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) {
            return try decompressed(using: algorithm, pageSize: pageSize, progressReport: progressReport)
        }

        guard let algorithm = algorithm.compression_algorithm else {
            progressReport(count, count)
            return self
        }

        return try decompressWithBuffer(algorithm: algorithm, uncompressedSize: uncompressedSize)
    }
}

public enum CompressionError: Error {
    case encodingError
}

extension Data {
    func compressWithBuffer(algorithm: compression_algorithm, progressReport: (Int, Int) -> Void = { _, _ in }) throws -> Data {
        // Step 1: create an array of UInt8 from the data

        let sourceSize = count

        progressReport(sourceSize, 0)

        // Step 2: Create the destination buffer to receive the compressed data
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceSize)
        defer {
            destinationBuffer.deallocate()
        }

        // Step 3: Compress the data with a given algorithm

        var compressedSize = 0

        try withUnsafeBytes { encodedSourceBuffer in
            guard let sourceBuffer = encodedSourceBuffer.bindMemory(to: UInt8.self).baseAddress else {
                throw CompressionError.encodingError
            }

            compressedSize = compression_encode_buffer(
                destinationBuffer, // Pointer to the buffer that receives the compressed data
                sourceSize, // Size of the destination buffer in bytes
                sourceBuffer, // Pointer to a buffer containing all of the source data
                sourceSize, // Size of the data in the source buffer in bytes.
                nil,
                algorithm
            )
        }

        // If the function can’t compress the entire input to fit into the provided destination buffer, or an error occurs, 0 is returned.
        guard compressedSize != 0 else {
            throw CompressionError.encodingError
        }

        progressReport(sourceSize, sourceSize)

        // Step 4: Convert bytes to Data
        // NOTE: Data(bytesNoCopy:...) will not work
        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    func decompressWithBuffer(algorithm: compression_algorithm, uncompressedSize: Int) throws -> Data {
        let decompressCapacity = uncompressedSize

        // Step 1: Create the destination buffer to receive the decompressed data
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressCapacity)
        defer {
            destinationBuffer.deallocate()
        }

        // Step 2: Access the raw bytes in the data’s buffer.
        let decodedBytesCount = withUnsafeBytes { encodedSourceBuffer in
            let typedPointer = encodedSourceBuffer.bindMemory(to: UInt8.self)

            // Step 3: decompress the data with same algorithm used for compressing
            return compression_decode_buffer(
                destinationBuffer,
                decompressCapacity,
                typedPointer.baseAddress!,
                self.count,
                nil,
                algorithm
            )
        }

        // Step 4: Convert bytes to Data
        return Data(bytes: destinationBuffer, count: decodedBytesCount)
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func _compressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: (Int, Int) -> Void = { _, _ in }) throws -> Self {
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

            progressReport(count, index)

            if rangeLength == 0 {
                break
            }
        }

        return compressedData
    }

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    func _decompressed(using algorithm: CompressionAlgorithm, pageSize: Int = 0, progressReport: @escaping (Int, Int) -> Void = { _, _ in }) throws -> Self {
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
