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

import Dispatch
import Foundation

// MARK: - Completion TypeAlias
typealias Completion = (Data?, Error?) -> Void


// MARK: - Mock Service

/// Test class used representing a service that could fail.
final class MockService {
    
    // MARK: - Public Instance Methods
    
    /// Performs a success.
    ///
    /// - Parameter completion: A `Completion` representing the handler.
    func success(completion: @escaping Completion) {
        performRequest(path: "get", completion: completion)
    }
    
    /// Performs a delayed success
    ///
    /// - Parameters:
    ///   - delay: A `Int` representing the amount of time to delay.
    ///   - completion: A `Completion` representing the handler.
    func delayedSuccess(delay: Int, completion: @escaping Completion) {
        performRequest(path: "delay/\(delay)", completion: completion)
    }
    
    /// Performs a failure.
    ///
    /// - Parameter completion: A `Completion` representing the handler.
    func failure(completion: @escaping Completion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let error = NSError(domain: "MockService", code: 400, userInfo: nil)
            completion(nil, error)
        }
    }
}


// MARK: - Private Instance Methods
private extension MockService {
    
    /// Performs a request to `https://httpbin.org`.
    ///
    /// - Parameters:
    ///   - path: A `String` representing the path to the resource.
    ///   - completion: A `Completion` representing the handler.
    func performRequest(path: String, completion: @escaping Completion) {
        let session = URLSession.defaultSession
        let url = URL(string: "https://httpbin.org/\(path)")!
        let task = session.dataTask(with: url) { (data, _, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}
