import Foundation

struct JpegExtractor {
}

// following resources were used to implement this parser:
// https://www.media.mit.edu/pia/Research/deepview/exif.html
// https://www.fileformat.info/format/jpeg/egff.htm
// http://vip.sugovica.hu/Sardi/kepnezo/JPEG%20File%20Layout%20and%20Format.htm
extension JpegExtractor: Extractor {
    func extractMetadataCreationTimestamp(input: inout Input) throws -> String {
        // checking JPEG SOI:
        let jpegSoi = try input.readU16()
        if jpegSoi != 0xFFD8 {
            throw IOError("Bad JPEG header, expected 0xFFD8, but received: \(String(jpegSoi, radix: 16, uppercase: true))")
        }
        // scrolling through fields until we find APP1:
        // TODO check for section size and break with meaningful error if APP1 was not found:
        while true {
            let fieldMarker = try input.readU16()
            let fieldLength = try input.readU16()
            // checking for APP1 marker:
            if fieldMarker == 0xFFE1 {
                // APP1 marker found, checking Exif header:
                let exifHeader = try input.readString(4)
                let exifHeaderSuffix = try input.readU16()
                if exifHeader != "Exif" || exifHeaderSuffix != 0x0000 {
                    throw IOError("JPEG APP1 field does not have valid Exif header")
                }
                // body is a valid TIFF,
                // size decrements:
                //   -2 field length
                //   -4 exif header
                //   -2 exif header suffix
                var exifBody = try input.section(ofLength: UInt64(fieldLength - 8), withByteOrder: Endianness.Big)
                return try TiffExtractor().extractMetadataCreationTimestamp(input: &exifBody)
            }
            // length includes the length itself:
            try input.ff(distance: UInt64(fieldLength - 2))
        }
    }
}
