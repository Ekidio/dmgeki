import Foundation

public enum DMGCompressionFormat: String, CaseIterable, Identifiable, Codable {
    case udzo = "UDZO"
    case ulfo = "ULFO"
    case udbz = "UDBZ"
    case udro = "UDRO"
    case udrw = "UDRW"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .udzo:
            return "UDZO (zlib Compressed - Recommended)"
        case .ulfo:
            return "ULFO (LZFSE Compressed - Fast Decompression)"
        case .udbz:
            return "UDBZ (bzip2 Compressed - Smaller Size)"
        case .udro:
            return "UDRO (Read-Only Uncompressed)"
        case .udrw:
            return "UDRW (Read/Write Uncompressed)"
        }
    }
    
    public var shortName: String {
        switch self {
        case .udzo: return "zlib (UDZO)"
        case .ulfo: return "LZFSE (ULFO)"
        case .udbz: return "bzip2 (UDBZ)"
        case .udro: return "Read-Only (UDRO)"
        case .udrw: return "Read/Write (UDRW)"
        }
    }
    
    public var formatDescription: String {
        switch self {
        case .udzo:
            return "Standard zlib compression. Supported on all macOS versions. Best balance of speed and size."
        case .ulfo:
            return "Apple LZFSE compression. Optimized for fast decompression on macOS 10.11 and later."
        case .udbz:
            return "High ratio bzip2 compression. Smaller file size, but slower to create and open."
        case .udro:
            return "Plain read-only disk image with no compression applied."
        case .udrw:
            return "Read/Write disk image. Typically used during staging or testing."
        }
    }
    
    public var isCompressed: Bool {
        return self == .udzo || self == .ulfo || self == .udbz
    }
}
