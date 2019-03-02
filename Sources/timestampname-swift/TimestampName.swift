import Foundation

func eprint(_ message: String) {
    guard let messageData = message.data(using: .utf8) else {
        return;
    }
    FileHandle.standardError.write(messageData)
}

func exec(cmdArgs: CmdArgs) throws {

}
