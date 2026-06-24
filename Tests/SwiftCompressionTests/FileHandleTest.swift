//
//  Created by Kurlovich Vitali on 6/23/26.
//

import Foundation
@testable import SwiftCompression
import Testing

struct FileHandleTest {
    @Test(arguments: DataPresset.all)
    func compress(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        // 1. Get the system temporary directory URL
        let tempDir = FileManager.default.temporaryDirectory

        // 2. Create a unique filename for isolation
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".moc")

        // 3. Clean up the file automatically when the test finishes
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // 4. Write mock data to the temporary file
        try data.write(to: fileURL, options: [.atomic])

        let handler = try FileHandle(forReadingFrom: fileURL)

        let compressed = try await handler.compress(using: configuration.algorithm, pageSize: configuration.pageSize) { total, progress in
            #expect(data.count == total)

            #expect(progress <= total)
        }

        #expect(compressed.isEmpty == data.isEmpty)

        let uncompress = try await compressed.decompress(using: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(uncompress == data)
    }

    @Test(arguments: DataPresset.all)
    func compressWriteToFile(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        // 1. Get the system temporary directory URL
        let tempDir = FileManager.default.temporaryDirectory

        // 2. Create a unique filename for isolation
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".moc")

        let compressedFileURL = tempDir.appendingPathComponent(UUID().uuidString + ".zmoc")

        FileManager.default.createFile(atPath: compressedFileURL.path(), contents: nil)

        // 3. Clean up the file automatically when the test finishes
        defer {
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.removeItem(at: compressedFileURL)
        }

        // 4. Write mock data to the temporary file
        try data.write(to: fileURL, options: [.atomic])

        let handler = try FileHandle(forReadingFrom: fileURL)
        let writeHandler = try FileHandle(forWritingTo: compressedFileURL)

        try await handler.compress(writeTo: writeHandler, using: configuration.algorithm, pageSize: configuration.pageSize) { total, progress in
            #expect(data.count == total)

            #expect(progress <= total)
        }

        try handler.close()
        try writeHandler.close()

        let compressed = try Data(contentsOf: compressedFileURL)

        #expect(compressed.isEmpty == data.isEmpty)

        let uncompress = try await compressed.decompress(using: configuration.algorithm, pageSize: configuration.pageSize) { total, progress in
            #expect(compressed.count == total)

            #expect(progress <= total)
        }


        #expect(uncompress == data)
    }

    @Test(arguments: DataPresset.all)
    func decompress(_ presset: DataPresset) async throws {
        let data = presset.data
        let configuration = presset.configuration

        // 1. Get the system temporary directory URL
        let tempDir = FileManager.default.temporaryDirectory

        // 2. Create a unique filename for isolation
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".moc")

        // 3. Clean up the file automatically when the test finishes
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // 4. Write mock data to the temporary file

        let compressed = try await data.compress(using: configuration.algorithm, pageSize: configuration.pageSize)
        try compressed.write(to: fileURL, options: [.atomic])

        let handler = try FileHandle(forReadingFrom: fileURL)

        let uncompress = try await handler.decompress(algorithm: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(uncompress == data)
    }
}
