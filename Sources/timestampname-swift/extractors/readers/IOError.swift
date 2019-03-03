enum IOError: Error {
    case endOfSection(position: Int, limit: Int, requested: Int)
}
