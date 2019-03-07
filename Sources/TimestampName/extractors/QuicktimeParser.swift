import Foundation

struct QuicktimeParser {
    private func searchBox(input: inout Input, requestedBoxType: String, requestedBoxUuid: (UInt64, UInt64)?) throws -> Input {
        // TODO handle box not found till the end of section
        while true {
            var offset: UInt64 = 0
            var boxBodyLength: UInt64
            let boxLength = try input.readU32();
            let boxType = try input.readString(4);
            // checking for large box:
            if boxLength == 1 {
                let boxLargeLength = try input.readU64();
                // box length includes header, have to make adjustments:
                // 4 bytes for box length
                // 4 bytes for box type
                // 8 bytes for box large length
                boxBodyLength = boxLargeLength - 16
                offset += 16
            } else {
                // box length includes header, have to make adjustments:
                // 4 bytes for box length
                // 4 bytes for box type
                boxBodyLength = UInt64(boxLength - 8)
                offset += 8
            }
            if boxType == requestedBoxType {
                if let uuid = requestedBoxUuid {
                    let msb = try input.readU64();
                    let lsb = try input.readU64();
                    boxBodyLength -= 16
                    if uuid.0 == msb && uuid.1 == lsb {
                        return try input.section(ofLength: boxBodyLength, withByteOrder: Endianness.Big)
                    }
                } else {
                    return try input.section(ofLength: boxBodyLength, withByteOrder: Endianness.Big)
                }
            }
            try input.ff(distance: boxBodyLength)
        }
    }

    func searchBox(input: inout Input, boxName: String) throws -> Input {
        return try searchBox(input: &input, requestedBoxType: boxName, requestedBoxUuid: nil)
    }

    func searchUuidBox(input: inout Input, boxUuid: (UInt64, UInt64)) throws -> Input {
        return try searchBox(input: &input, requestedBoxType: "uuid", requestedBoxUuid: boxUuid)
    }
}
