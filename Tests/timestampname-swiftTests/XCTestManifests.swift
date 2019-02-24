import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(timestampname_swiftTests.allTests),
    ]
}
#endif