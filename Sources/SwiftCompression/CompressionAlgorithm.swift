//
//  Created by Kurlovich Vitali on 6/20/26.
//

import Compression
import Foundation

public enum CompressionAlgorithm: UInt8, Hashable, Codable, CaseIterable, Sendable {
    case none = 0
    case lz4
    case lzma
    case zlib
    case brotli
}

extension CompressionAlgorithm {
    var algorithm: Algorithm? {
        switch self {
        case .none:
            return nil
        case .lz4:
            return .lz4
        case .lzma:
            return .lzma
        case .zlib:
            return .zlib
        case .brotli:
            return .brotli
        }
    }
}
