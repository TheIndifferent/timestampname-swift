import Foundation

struct TiffExtractor {
}

// following resources were used to implement this parser:
// https://www.adobe.io/content/dam/udp/en/open/standards/tiff/TIFF6.pdf
extension TiffExtractor: Extractor {

    private func determineTiffEndianness(forHeader tiffEndiannessHeader: String) throws -> Endianness {
        switch tiffEndiannessHeader {
        case "II":
            return Endianness.Little
        case "MM":
            return Endianness.Big
        default:
            throw IOError("Bad TIFF header, expected one of 'II' or 'MM', but received: \(tiffEndiannessHeader)")
        }
    }

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

        // TODO find a way to simplify this:
        // rewing back because TIFF offsets are absolute:
        try input.seek(to: 0)
        // create a section input with specified engianness:
        var bodyInput = try input.section(ofLength: input.count, withByteOrder: bo)
        // ff to skip 2 bytes header:
        try bodyInput.seek(to: 2)

        // Bytes 2-3 An arbitrary but carefully chosen number (42)
        // that further identifies the file as a TIFF file.
        let tiffMagic = try bodyInput.readU16();
        if tiffMagic != 42 {
            throw IOError("Bad TIFF magic number, expected 42 but got: \(tiffMagic)")
        }

        var ifdOffsets = [UInt32]()
        var dateTagOffsets = [UInt32]()

        // Bytes 4-7 The offset (in bytes) of the first IFD.
        ifdOffsets.append(try bodyInput.readU32())

        var earliestCreationDate = ""
        while true {
            if ifdOffsets.isEmpty && dateTagOffsets.isEmpty {
                // TIFF no more offsets to scavenge
                break
            }

            // TODO should sorting happen here?
            // sorting to traverse file forward-only:
            ifdOffsets.sort()
            dateTagOffsets.sort()

            let nextIfdOffset = ifdOffsets.first ?? UInt32.max
            let nextDateTagOffset = dateTagOffsets.first ?? UInt32.max

            if nextDateTagOffset < nextIfdOffset {
                dateTagOffsets.removeFirst()
                if nextDateTagOffset + 20 >= bodyInput.count {
                    throw IOError("""
                                  Date value offset beyond section length, \
                                  offset: \(nextDateTagOffset), count: \(bodyInput.count)
                                  """)
                }
                try bodyInput.seek(to: UInt64(nextDateTagOffset))
                let dateValue = try bodyInput.readString(19)
                if earliestCreationDate.isEmpty {
                    earliestCreationDate = dateValue
                } else {
                    if dateValue < earliestCreationDate {
                        earliestCreationDate = dateValue
                    }
                }
            } else {
                ifdOffsets.removeFirst()
                // check for overflow, seek position +2 bytes IFD field count +4 bytes next IFD offset:
                if nextIfdOffset + 6 >= bodyInput.count {
                    throw IOError("""
                                  IFD offset goes beyond section length, \
                                  offset: \(nextIfdOffset), count: \(bodyInput.count)
                                  """)
                }
                try bodyInput.seek(to: UInt64(nextIfdOffset))
                // 2-byte count of the number of directory entries (i.e., the number of fields)
                let fields = try bodyInput.readU16()
                for _ in 0..<fields {
                    // Bytes 0-1 The Tag that identifies the field
                    let fieldTag = try bodyInput.readU16()
                    // Bytes 2-3 The field Type
                    let fieldType = try bodyInput.readU16()
                    // Bytes 4-7 The number of values, Count of the indicated Type
                    let fieldCount = try bodyInput.readU32()
                    // Bytes 8-11 The Value Offset, the file offset (in bytes) of the Value for the field
                    let fieldValueOffset = try bodyInput.readU32()
                    switch fieldTag {
                    // 0x0132: DateTime
                    // 0x9003: DateTimeOriginal
                    // 0x9004: DateTimeDigitized
                    case 0x0132, 0x9003, 0x9004:
                        if fieldType != 2 {
                            throw IOError("""
                                          Expected tag has unexpected type, \
                                          tag: \(fieldTag), type: \(fieldType)
                                          """)
                        }
                        if fieldCount != 20 {
                            throw IOError("""
                                          Expected tag has unexpected size, \
                                          tag: \(fieldTag), size: \(fieldCount)
                                          """)
                        }
                        dateTagOffsets.append(fieldValueOffset)
                    case 0x8769:
                        if fieldType != 4 {
                            throw IOError("""
                                          Expected tag has unexpected type, \
                                          tag: \(fieldTag), type: \(fieldType)
                                          """)
                        }
                        if fieldCount != 1 {
                            throw IOError("""
                                          Expected tag has unexpected size, \
                                          tag: \(fieldTag), size: \(fieldCount)
                                          """)
                        }
                        ifdOffsets.append(fieldValueOffset)
                    default:
                        continue
                    }
                }
                // followed by a 4-byte offset of the next IFD (or 0 if none).
                // (Do not forget to write the 4 bytes of 0 after the last IFD.)
                let parsedIfdOffset = try bodyInput.readU32()
                if parsedIfdOffset != 0 {
                    ifdOffsets.append(parsedIfdOffset)
                }
            }
        }

        // TODO for now using date parsing to verify that value matches the expected format:
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        if dateFormatter.date(from: earliestCreationDate) != nil {
            return try reformatExifTimestamp(timestamp: &earliestCreationDate)
        }
        // if we are here - parsing failed, second attempt:
        // might be bug in Samsung S9 camera, panorama photo has different date format:
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if dateFormatter.date(from: earliestCreationDate) != nil {
            return try reformatExifTimestamp(timestamp: &earliestCreationDate)
        }
        // if we are still here - second attempt failed, quitting:
        throw IOError("""
                      Failed to parse exif date: \
                      \(earliestCreationDate)
                      """)
    }

    private func reformatExifTimestamp(timestamp: inout String) throws -> String {
        timestamp.removeAll(where: { $0 == ":" as Character || $0 == "-" as Character })
        if let spaceIndex = timestamp.firstIndex(of: " ") {
            timestamp.remove(at: spaceIndex)
            timestamp.insert("-", at: spaceIndex)
            return timestamp
        }
        throw IOError("""
                      Index of space character was not found in string: \
                      \(timestamp)
                      """)
    }
}
