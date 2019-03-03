import Foundation

enum Endianness {
    case Big
    case Little
}

protocol Input {
    var count: Int { get }
    mutating func section(ofLength: Int, withByteOrder: Endianness) throws -> Input;
    mutating func readString(_ ofLength: Int) throws -> String;
    mutating func readU16() throws -> UInt16;
}
