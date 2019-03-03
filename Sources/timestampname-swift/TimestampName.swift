import Foundation

func eprint(_ message: String) {
    guard let messageData = message.data(using: .utf8) else {
        return;
    }
    // flush stdout so \r will not cripple the output:
    FileHandle.standardOutput.synchronizeFile()
    FileHandle.standardError.write(messageData)
}

func info(_ message: String) {
    // cannot use normal print because need to flush the stdout before stderr:
    guard let messageData = message.data(using: .utf8) else {
        return;
    }
    FileHandle.standardOutput.write(messageData)
}

fileprivate struct CollectedMetadata {
    let items: Array<FileMetadata>
    let longestSourceName: Int
}

func execute(cmdArgs: CmdArgs) throws {
    info("Scanning for files...")
    let filesList = try listFiles()
    info(" \(filesList.count) files found.\n")

    let collectedMetadata = try processFiles(filesList, utc: cmdArgs.utc)

    if collectedMetadata.items.count == 0 {
        info("No supported files found.\n")
        exit(0)
    }

    info("Preparing rename operations...")
    let renameOperations = try prepareRenameOperations(items: collectedMetadata.items, noPrefix: cmdArgs.noPrefix)
    info(" done.\n")

    info("Verifying:\n")
    try verifyRenameOperations(operations: renameOperations, longestSourceName: collectedMetadata.longestSourceName)
    info("done.\n")

    try executeOperations(operations: renameOperations, dryRun: cmdArgs.dryRun)
    info("\nFinished.\n")
}

fileprivate func listFiles() throws -> Array<String> {
    var isDir: ObjCBool = false
    let fm = FileManager.default
    let files = try fm.contentsOfDirectory(atPath: ".")
    var result = [String]()
    for f in files {
        if !f.hasPrefix(".") && fm.fileExists(atPath: f, isDirectory: &isDir) && !isDir.boolValue {
            result.append(f)
        }
    }
    return result
}

fileprivate func processFiles(_ filesList: Array<String>, utc: Bool) throws -> CollectedMetadata {
    let extractors: [String: Extractor] = [
        "nef": TiffExtractor(),
        "dng": TiffExtractor()
    ]
    var items = [FileMetadata]()
    var longestSourceName = 0
    for (index, fileName) in filesList.enumerated() {
        info("\rProcessing files: \(index + 1)/\(filesList.count)...")
        let fileUrl = URL(fileURLWithPath: fileName)
        let fileExt = fileUrl.pathExtension.lowercased()
        if let extractor = extractors[fileExt] {
            var data = try Data(contentsOf: fileUrl, options: .alwaysMapped)
            var input: Input = DataInput(data: data)
            let timestamp = try extractor.extractMetadataCreationTimestamp(input: &input)
            let md = FileMetadata(fileName: fileName, creationTimestamp: timestamp, fileExt: fileExt)
            items.append(md)
            if fileName.count > longestSourceName {
                longestSourceName = fileName.count
            }
        }
    }
    info(" \(items.count) supported files found.\n")
    return CollectedMetadata(items: items, longestSourceName: longestSourceName)
}
