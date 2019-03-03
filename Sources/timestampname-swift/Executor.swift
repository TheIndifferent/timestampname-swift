import Foundation

func executeOperations(operations: Array<RenameOperation>, dryRun: Bool) throws {
    let fm = FileManager.default
    let readOnlyAttribute: [FileAttributeKey: Any] = [
        .posixPermissions: 0444
    ]
    for (index, operation) in operations.enumerated() {
        info("\rRenaming files: \(index+1)/\(operations.count)")
        if !dryRun {
            try fm.moveItem(atPath: operation.from, toPath: operation.to)
            try fm.setAttributes(readOnlyAttribute, ofItemAtPath: operation.to)
        }
    }
    info(" done.\n")
}
