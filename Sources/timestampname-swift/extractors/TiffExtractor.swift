import Foundation

struct TiffExtractor {
}

extension TiffExtractor: Extractor {

    private func determineTiffEndianness(forHeader tiffEndiannessHeader: String) throws -> Endianness {
        switch tiffEndiannessHeader {
        case "II":
            return Endianness.Little
        case "MM":
            return Endianness.Big
        default:
            throw IOError("Bad TIFF header: \(tiffEndiannessHeader)")
        }
    }

    // https://www.adobe.io/content/dam/udp/en/open/standards/tiff/TIFF6.pdf
    func extractMetadataCreationTimestamp(input: inout Input) throws -> String {
        // Bytes 0-1: The byte order used within the file. Legal values are:
        // “II” (4949.H)
        // “MM” (4D4D.H)
        let tiffEndiannessHeader: String = try input.readString(2)
        // In the “II” format, byte order is always from the least significant byte to the most
        // significant byte, for both 16-bit and 32-bit integers.
        // This is called little-endian byte order.
        //  In the “MM” format, byte order is always from most significant to least
        // significant, for both 16-bit and 32-bit integers.
        // This is called big-endian byte order
        let bo = try determineTiffEndianness(forHeader: tiffEndiannessHeader)
        let boInput = try input.section(ofLength: input.count - 2, withByteOrder: bo)
        // Bytes 2-3 An arbitrary but carefully chosen number (42)
        // that further identifies the file as a TIFF file.
        let tiffMagic = try input.readU16();
        if tiffMagic != 42 {
            throw IOError("Bad TIFF magic number, expected 42 but got: \(tiffMagic)")
        }

        return ""
    }
}
