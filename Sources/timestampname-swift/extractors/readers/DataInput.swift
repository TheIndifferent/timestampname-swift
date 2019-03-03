import Foundation

struct DataInput {
    let data: Data
    let bo: Endianness
    let offset: UInt64
    var cursor: UInt64 = 0
    let limit: UInt64

    init(data: Data) {
        self.data = data
        self.offset = 0
        self.limit = UInt64(data.count)
        self.bo = Endianness.Big
    }

    fileprivate init(data: Data, offset: UInt64, limit: UInt64, withByteOrder: Endianness) {
        self.data = data
        self.offset = offset
        self.limit = limit
        self.bo = withByteOrder
    }
}

extension DataInput: Input {

    var count: UInt64 {
        return UInt64(self.data.count)
    }

    private func checkOperationOverflows(targetOffset: UInt64, operation: String) throws {
        let totalOffset = self.offset + self.cursor + targetOffset
        if totalOffset >= UInt64(Int.max) {
            throw IOError("""
                          '\(operation)' operation overflows platform Int value, \
                          offset: \(offset), cursor: \(cursor), target offset: \(targetOffset), max int: \(Int.max)
                          """)
        }
        let localOffset = self.cursor + targetOffset
        if localOffset > self.limit {
            throw IOError("""
                          '\(operation)' operation overflows current section, \
                          cursor: \(self.cursor), target offset: \(targetOffset), limit: \(self.limit)
                          """)
        }
    }

    mutating func section(ofLength: UInt64, withByteOrder: Endianness) throws -> Input {
        try checkOperationOverflows(targetOffset: ofLength, operation: "section")
        let start = self.offset + self.cursor
        return DataInput(data: self.data, offset: start, limit: ofLength, withByteOrder: withByteOrder)
    }

    mutating func seek(to: UInt64) throws {
        try checkOperationOverflows(targetOffset: to, operation: "seek")
        self.cursor = to
    }

    mutating func readString(_ ofLength: UInt64) throws -> String {
        try checkOperationOverflows(targetOffset: ofLength, operation: "readString")
        let start = self.offset + self.cursor
        if let res = String(data: self.data.subdata(in: Int(start)..<Int(start + ofLength)), encoding: .ascii) {
            self.cursor += ofLength
            return res
        }
        throw IOError("""
                      Failed to read string: \
                      position: \(start), limit: \(self.limit), requested: \(ofLength)
                      """)
    }

    mutating func readU16() throws -> UInt16 {
        try checkOperationOverflows(targetOffset: 2, operation: "readU16")
        let start = self.offset + self.cursor
        let res: UInt16 = self.data
                .subdata(in: Int(start)..<Int(start + 2))
                .withUnsafeBytes { $0.pointee }
        self.cursor += 2
        switch bo {
        case .Big:
            return res.bigEndian
        case .Little:
            return res.littleEndian
        }
    }

    mutating func readU32() throws -> UInt32 {
        try checkOperationOverflows(targetOffset: 4, operation: "readU32")
        let start = self.offset + self.cursor
        let res: UInt32 = self.data
                .subdata(in: Int(start)..<Int(start + 4))
                .withUnsafeBytes { $0.pointee }
        self.cursor += 4
        switch bo {
        case .Big:
            return res.bigEndian
        case .Little:
            return res.littleEndian
        }
    }
}
