import Foundation

fileprivate extension String {
    func pad(_ toLength: Int) -> String {
        if self.count < toLength {
            return String(repeating: " " as Character, count: toLength - self.count) + self
        }
        return self
    }
}

func verifyRenameOperations(operations: Array<RenameOperation>, longestSourceName: Int) throws {
    var duplicates = Set<String>()
    for operation in operations {
        info("    \(operation.from.pad(longestSourceName))    =>    \(operation.to)\n")
        // check for target name duplicates:
        if duplicates.contains(operation.to) {
            throw FileError(fileName: operation.to, message: "Duplicate target file")
        }
        duplicates.insert(operation.to)
        // check for renaming duplicates:
        if operation.from != operation.to && FileManager.default.fileExists(atPath: operation.to) {
            throw FileError(fileName: operation.to, message: "File already exists on file system")
        }
    }
}
