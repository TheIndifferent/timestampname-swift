import Foundation

enum Endianness {
    case Big
    case Little
}

protocol Input {
    var count: UInt64 { get }
    mutating func section(ofLength: UInt64, withByteOrder: Endianness) throws -> Input;
    mutating func seek(to: UInt64) throws;
    mutating func ff(distance: UInt64) throws;
    mutating func readString(_ ofLength: UInt64) throws -> String;
    mutating func readU16() throws -> UInt16;
    mutating func readU32() throws -> UInt32;
}
