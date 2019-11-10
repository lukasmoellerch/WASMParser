import XCTest

import WASMParserTests

var tests = [XCTestCaseEntry]()
tests += WASMParserTests.allTests()
XCTMain(tests)
