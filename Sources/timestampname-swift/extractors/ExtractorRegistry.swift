import Foundation

struct ExtractorRegistry {
    private let extractors: [String: Extractor] = [
        "nef": TiffExtractor(),
        "dng": TiffExtractor()
    ]

    func findExtractor(fileName: String, utc: Bool) -> Extractor? {
        if let fileUrl = URL(string: fileName) {
            let fileExt = fileUrl.pathExtension
            info("Path extension: \(fileExt)\n")
            if let extractor = extractors[fileExt] {
                return extractor
            }
        }
        return nil
    }
}
