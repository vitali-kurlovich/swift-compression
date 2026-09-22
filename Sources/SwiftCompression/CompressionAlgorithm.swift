//
//  Created by Kurlovich Vitali on 6/20/26.
//

#if os(anyAppleOS)
    import enum Compression.Algorithm
#endif

public enum CompressionAlgorithm: UInt8, Hashable, Codable, CaseIterable, Sendable {
    case none = 0
    case lzma = 1
    #if os(anyAppleOS)
        case zlib = 2
        case brotli = 3
        case lz4 = 4
    #endif
}

#if os(anyAppleOS)
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
#endif
