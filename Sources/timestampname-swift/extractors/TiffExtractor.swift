import Foundation

struct TiffExtractor {

}

extension TiffExtractor: Extractor {
    // https://www.adobe.io/content/dam/udp/en/open/standards/tiff/TIFF6.pdf
    func extractMetadataCreationTimestamp(input: inout Input) throws -> String {
        // Bytes 0-1: The byte order used within the file. Legal values are:
        // “II” (4949.H)
        // “MM” (4D4D.H)
        let tiffEndiannessHeader = try input.readString(2)
        info(tiffEndiannessHeader)
        info("\n")
        return ""
    }
}
