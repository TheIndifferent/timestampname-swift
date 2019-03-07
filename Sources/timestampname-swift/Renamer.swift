import Foundation

extension FileMetadata: Comparable {

    public static func == (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
        return lhs.fileName == rhs.fileName && lhs.creationTimestamp == rhs.creationTimestamp
    }

    public static func < (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
        let ct1 = lhs.creationTimestamp
        let ct2 = rhs.creationTimestamp
        if ct1 < ct2 {
            return true
        }
        if ct1 > ct2 {
            return false
        }
        // if we are still here - timestamps are even:
        // workaround for Android way of dealing with same-second shots:
        // 20180430_184327.jpg
        // 20180430_184327(0).jpg
        let l1 = lhs.fileName.count
        let l2 = rhs.fileName.count
        if l1 < l2 {
            return true
        }
        if l1 > l2 {
            return false
        }
        // now both timestamps and file names are equal,
        // comparing file names lexicographically:
        return lhs.fileName < rhs.fileName
    }
}

fileprivate func determinePrefixWidth(itemCount: Int) throws -> Int {
    // TODO check this with exactly 99 and 100 files:
    switch itemCount {
    case 0...9:
        return 1
    case 10...99:
        return 2
    case 100...999:
        return 3
    case 1000...9999:
        return 4
    case 10000...99999:
        return 5
    default:
        throw TaskError("Too many files: \(itemCount)")
    }
}

fileprivate func formatTargetFileName(item: FileMetadata, index: Int, prefixFormat: String, noPrefix: Bool) -> String {
    if noPrefix {
        return "\(item.creationTimestamp).\(item.fileExt)"
    }
    return "\(String(format: prefixFormat, index+1))-\(item.creationTimestamp).\(item.fileExt)"
}

func prepareRenameOperations(items: Array<FileMetadata>, noPrefix: Bool) throws -> Array<RenameOperation> {
    let prefixWidth = try determinePrefixWidth(itemCount: items.count)
    let prefixFormat = "%0\(prefixWidth)d"
    let sortedItems = items.sorted()

    var operations = [RenameOperation]()
    for (index, metadata) in sortedItems.enumerated() {
        let operation = RenameOperation(from: metadata.fileName,
                                        to: formatTargetFileName(item: metadata,
                                                                 index: index,
                                                                 prefixFormat: prefixFormat,
                                                                 noPrefix: noPrefix))
        operations.append(operation)
    }
    return operations
}
