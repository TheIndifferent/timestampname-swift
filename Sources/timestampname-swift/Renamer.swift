import Foundation

fileprivate func compareFileMetadatas(_ md1: FileMetadata, _ md2: FileMetadata) throws -> Bool {
    if md1.fileName == md2.fileName {
        throw FileError(fileName: md1.fileName, message: "File encountered twice")
    }
    let ct1 = md1.creationTimestamp
    let ct2 = md2.creationTimestamp
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
    let l1 = md1.fileName.count
    let l2 = md2.fileName.count
    if l1 < l2 {
        return true
    }
    if l1 > l2 {
        return false
    }
    // now both timestamps and file names are equal,
    // equal names case was checked at the beginning:
    if md1.fileName < md2.fileName {
        return true
    } else {
        return false
    }
}

fileprivate func determinePrefixWidth(itemCount: Int) throws -> Int {
    // TODO check this with exactly 99 and 100 files:
    switch itemCount {
    case 0..<10:
        return 1
    case 10..<100:
        return 2
    case 100..<1000:
        return 3
    case 1000..<10000:
        return 4
    case 10000..<100000:
        return 5
    default:
        throw TaskError("Too many files: \(itemCount)")
    }
}

fileprivate func formatTargetFileName(item: FileMetadata, index: Int, noPrefix: Bool) -> String {
    if noPrefix {
        return "\(item.creationTimestamp).\(item.fileExt)"
    }
    return "\(index+1)-\(item.creationTimestamp).\(item.fileExt)"
}

func prepareRenameOperations(items: Array<FileMetadata>, noPrefix: Bool) throws -> Array<RenameOperation> {
    let prefixWidth = try determinePrefixWidth(itemCount: items.count)
    let sortedItems = try items.sorted(by: compareFileMetadatas)

    var operations = [RenameOperation]()
    for (index, metadata) in items.enumerated() {
        let operation = RenameOperation(from: metadata.fileName,
                                        to: formatTargetFileName(item: metadata, index: index, noPrefix: noPrefix))
        operations.append(operation)
    }
    return operations
}
