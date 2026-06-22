//
//  Created by Kurlovich Vitali on 6/22/26.
//

import Foundation

public struct CompressedDataPayload: Hashable, Sendable {
    public let originalSize: UInt32
    public let compressedSize: UInt32
    public let algorithm: CompressionAlgorithm
}

extension CompressedDataPayload {
    func data() -> Data {
        var capacity = MemoryLayout.size(ofValue: algorithm.rawValue)

        if algorithm != .none {
            capacity += MemoryLayout.size(ofValue: originalSize)
        }

        var data = Data(count: capacity)

        data.withUnsafeMutableBytes { pointer in
            let rawValue = algorithm.rawValue

            pointer.storeBytes(of: rawValue, as: type(of: rawValue))

            if algorithm != .none {
                pointer.storeBytes(of: originalSize.bigEndian,
                                   toByteOffset: MemoryLayout.size(ofValue: rawValue),
                                   as: type(of: originalSize))
            }
        }

        return data
    }
}
