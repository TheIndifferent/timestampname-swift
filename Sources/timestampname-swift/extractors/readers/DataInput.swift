import Foundation

struct DataInput {
    let data: Data
    let bo: Endianness
    let offset: Int
    var cursor = 0
    let limit: Int

    init(data: Data) {
        self.data = data
        self.offset = 0
        self.limit = data.count
        self.bo = Endianness.Big
    }

    fileprivate init(data: Data, offset: Int, limit: Int, withByteOrder: Endianness) {
        self.data = data
        self.offset = offset
        self.limit = limit
        self.bo = withByteOrder
    }
}

extension DataInput: Input {

    mutating func section(ofLength: Int, withByteOrder: Endianness) throws -> Input {
        let start = self.offset + self.cursor
        if start + ofLength >= self.data.count {
            throw IOError.endOfSection(position: start, limit: self.limit, requested: ofLength)
        }
        return DataInput(data: self.data, offset: start, limit: ofLength, withByteOrder: withByteOrder)
    }

    mutating func readString(_ ofLength: Int) throws -> String {
        let start = self.offset + self.cursor
        if start + ofLength >= self.data.count {
            throw IOError.endOfSection(position: start, limit: self.limit, requested: ofLength)
        }
        let res: String = self.data
                // TODO subscript is not recognized?
                .subdata(in: start..<start+ofLength)
                .withUnsafeBytes { $0.pointee }
        self.cursor += ofLength
        return res
    }

    mutating func readU16() throws -> UInt16 {
        let start = self.offset + self.cursor
        if start + 2 >= self.data.count {
            throw IOError.endOfSection(position: start, limit: self.limit, requested: 2)
        }
        let res: UInt16 = self.data
                .subdata(in: start..<start + 2)
                .withUnsafeBytes { $0.pointee }
        self.cursor += 2
        switch bo {
        case .Big:
            return res.bigEndian
        case .Little:
            return res.littleEndian
        }
    }
}
