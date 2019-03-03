enum IOError: Error {
    case endOfSection(position: Int, limit: Int, requested: Int)
    case failedToReadString(position: Int, requested: Int)
    case badFileStructure(_ description: String)
}
