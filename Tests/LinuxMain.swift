import XCTest
// 1
@testable import AppTests

// 2
XCTMain([
    testCase(AcronymTests.allTests),
    testCase(CategoryTests.allTests),
    testCase(UserTests.allTests)
    ])
