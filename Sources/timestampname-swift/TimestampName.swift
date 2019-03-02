import Foundation

func eprint(_ message: String) {
    guard let messageData = message.data(using: .utf8) else {
        return;
    }
    FileHandle.standardError.write(messageData)
}

func info(_ message: String) {
    print(message, separator: "", terminator: "")
}

func execute(cmdArgs: CmdArgs) throws {
    info("Scanning for files...")
    let filesList = try listFiles()
    info(" \(filesList.count) files found.\n")

    // TODO process files

    // TODO exit if no supported files found

    info("Preparing rename operations...")
    // TODO collect operations list
    info(" done.\n")

    info("Verifying:")
    // TODO verify and print out every operation
    info("done.\n")

    // TODO execute operations
    info("\nFinished.\n")
}

func listFiles() throws -> Array<String> {
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
