import Foundation

struct Cr3Extractor {
    // pre-calculated MSB and LSB for Canon box UUID,
    // the following code was used to calculate it:
    //    private func canonBoxUuid() throws -> (UInt64, UInt64) {
    //        if let msb = UInt64("85c0b687820f11e0", radix: 16),
    //           let lsb = UInt64("8111f4ce462b6a48", radix: 16) {
    //            return (msb, lsb)
    //        }
    //        throw TaskError("Failed to extract UUID MSB and LSB from hex string: '85c0b687820f11e08111f4ce462b6a48'")
    //    }
    static private let CANON_BOX_UUID: (UInt64, UInt64) = (9637903895691727328, 9300483872274475592)
}

// following resources were used to implement this parser:
// https://github.com/lclevy/canon_cr3
extension Cr3Extractor: Extractor {

    func extractMetadataCreationTimestamp(input: inout Input) throws -> String {
        let qt = QuicktimeParser()
        let tiff = TiffExtractor()
        var moovBox = try qt.searchBox(input: &input, boxName: "moov")
        var canonBox = try qt.searchUuidBox(input: &moovBox, boxUuid: Cr3Extractor.CANON_BOX_UUID)

        var cmt1Box = try qt.searchBox(input: &canonBox, boxName: "CMT1")
        let cmt1Timestamp = try tiff.extractMetadataCreationTimestamp(input: &cmt1Box)

        try canonBox.seek(to: 0)
        var cmt2Box = try qt.searchBox(input: &canonBox, boxName: "CMT2")
        let cmt2Timestamp = try tiff.extractMetadataCreationTimestamp(input: &cmt2Box)

        if cmt1Timestamp < cmt2Timestamp {
            return cmt1Timestamp
        } else {
            return cmt2Timestamp
        }
    }
}
