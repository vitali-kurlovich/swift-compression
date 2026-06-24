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

        let compressed = try await handler.compress(algorithm: configuration.algorithm, pageSize: configuration.pageSize)

        #expect(compressed.isEmpty == data.isEmpty)

        let uncompress = try await compressed.decompress(using: configuration.algorithm, pageSize: configuration.pageSize)

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
