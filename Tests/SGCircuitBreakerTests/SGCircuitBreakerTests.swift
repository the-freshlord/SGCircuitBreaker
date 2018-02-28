//MIT License
//
//Copyright (c) 2017 Manny Guerrero
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

@testable import SGCircuitBreaker
import XCTest

final class SGCircuitBreakerTests: XCTestCase {
    
    // MARK: - Private Instance Attributes
    private var mockService: MockService!
    private var circuitBreaker: SGCircuitBreaker!
    
    
    // MARK: - Public Class Attributes
    static var allTests = [
        ("testSuccess", testSuccess),
        ("testFailure", testFailure),
        ("testTimeout", testTimeout),
        ("testTripped", testTripped)
    ]
    
    
    // MARK: - Setup & Tear Down
    override func setUp() {
        super.setUp()
        mockService = MockService()
    }
    
    override func tearDown() {
        super.tearDown()
        circuitBreaker.reset()
        circuitBreaker.workToPerform = nil
        circuitBreaker.tripped = nil
        circuitBreaker = nil
        mockService = nil
    }
}


// MARK: - Functional Tests
extension SGCircuitBreakerTests {
    func testSuccess() {
        let successExpectation = expectation(description: "Test register success")
        circuitBreaker = SGCircuitBreaker()
        circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
            self?.mockService.success { (data, error) in
                XCTAssertNotNil(data, "Value should not be nil")
                XCTAssertNil(error, "Value should be nil")
                circuitBreaker.success()
            }
        }
        circuitBreaker.successful = { _ in
            successExpectation.fulfill()
        }
        circuitBreaker.start()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFailure() {
        let failureExpectation = expectation(description: "Test register failure")
        circuitBreaker = SGCircuitBreaker(maxFailures: 1)
        circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
            self?.mockService.failure { (data, error) in
                XCTAssertNil(data, "Value should be nil")
                XCTAssertNotNil(error, "Value should not be nil")
                circuitBreaker.failure()
            }
        }
        circuitBreaker.tripped = { _, _ in
            failureExpectation.fulfill()
        }
        circuitBreaker.start()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testTimeout() {
        let timeoutExpectation = expectation(description: "Test timeout")
        circuitBreaker = SGCircuitBreaker(timeout: 3)
        circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
            switch circuitBreaker.failureCount {
            case 0:
                self?.mockService.delayedSuccess(delay: 5) { _, _  in }
            default:
                self?.mockService.success { _, _  in
                    circuitBreaker.success()
                    timeoutExpectation.fulfill()
                }
            }
        }
        circuitBreaker.start()
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testTripped() {
        let didTripExpectation = expectation(description: "Test did trip")
        circuitBreaker = SGCircuitBreaker(maxFailures: 1)
        circuitBreaker.tripped = { (circuitBreaker, error) in
            XCTAssertEqual(circuitBreaker.state, .open, "Circuit breaker should be opened")
            XCTAssertEqual(
                circuitBreaker.failureCount,
                circuitBreaker.maxFailures, "Circuit breaker failure count was not incremented correctly"
            )
            guard let error = error,
                  let mockError = error as? NSError else {
                    XCTFail("Circuit breaker did not persist last error")
                    return
            }
            XCTAssertEqual(mockError.code, 400, "Circuit breaker maintained incorrect error")
            circuitBreaker.reset()
            didTripExpectation.fulfill()
        }
        circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
            self?.mockService.failure { (_, error) in
                circuitBreaker.failure(error: error)
            }
        }
        circuitBreaker.start()
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, "Value should be nil")
        }
    }
}
