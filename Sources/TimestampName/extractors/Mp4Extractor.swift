import Foundation

struct Mp4Extractor {
    // pre-calculated duration between 1904-01-01 and 1970-01-01:
    static private let MP4_EPOCH_OFFSET: UInt64 = 2082844800
    let utc: Bool
}

extension Mp4Extractor: Extractor {

    private func formatCreationTimestamp(mp4Epoch: UInt64) -> String {
        let since1970 = mp4Epoch - Mp4Extractor.MP4_EPOCH_OFFSET
        let date = Date(timeIntervalSince1970: TimeInterval(since1970))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        if utc {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        return dateFormatter.string(from: date)
    }

    func extractMetadataCreationTimestamp(input: inout Input) throws -> String {
        let qt = QuicktimeParser()
        var moovBox = try qt.searchBox(input: &input, boxName: "moov")
        var mvhdBox = try qt.searchBox(input: &moovBox, boxName: "mvhd")
        let mvhdVersionAndFlags = try mvhdBox.readU32()
        let mvhdVersion = mvhdVersionAndFlags >> 24
        switch mvhdVersion {
        case 0:
            let creationTime = try mvhdBox.readU32()
            let modificationTime = try mvhdBox.readU32()
            if creationTime < modificationTime {
                return formatCreationTimestamp(mp4Epoch: UInt64(creationTime))
            } else {
                return formatCreationTimestamp(mp4Epoch: UInt64(modificationTime))
            }
        case 1:
            let creationTime = try mvhdBox.readU64()
            let modificationTime = try mvhdBox.readU64()
            if creationTime < modificationTime {
                return formatCreationTimestamp(mp4Epoch: creationTime)
            } else {
                return formatCreationTimestamp(mp4Epoch: modificationTime)
            }
        default:
            throw IOError("Unsupported 'mvhd' box version: \(mvhdVersion)")
        }
    }
}
