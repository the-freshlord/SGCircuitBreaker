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

// MARK: - Breaker State Enum

/// An enum that defines the different states a circut breaker can have.
///
/// - open: When the circut breaker is triped from an error. This means the cicuit breaker is broken.
/// - halfOpened: When the timeout has been reset. This means the circuit breaker is experiencing errors.
/// - closed: When the circut breaker can execute the context closure. This means that the cicuit breaker is
///           functioning normally.
public enum BreakerState {
    case open
    case halfOpened
    case closed
}


// MARK: - Circuit Breaker

/// A class that encapsulates the circuit breaker design pattern.
public class SGCircuitBreaker {
    
    // MARK: - Public Instance Attributes For Circuit Breaker Behavior
    
    /// Closure that represents the registered work that should be executed but could fail.
    public var workToPerform: ((SGCircuitBreaker) -> Void)?
    
    /// Closure that represents the registered error handler for when an error occurs in the circuit breaker.
    /// This can be fired if the registered work keeps failing and the max number of retries has been reached.
    public var tripped: ((SGCircuitBreaker, Error?) -> Void)?
    
    /// Closure that represents the registered handler for when the circuit breaker successfully completed the
    /// registered work.
    public var successful: ((SGCircuitBreaker) -> Void)?
    
    /// Closure that represents the registered handler for when the circuit breaker reaches the timeout. This
    /// can be used for canceling the work.
    public var timedOut: ((SGCircuitBreaker) -> Void)?
    
    /// Number of failures allowed for retrying to performing the registered work before tripping.
    public let maxFailures: Int
    
    /// Current number of failures.
    public private(set) var failureCount = 0
    
    /// The current state of the circuit breaker.
    public var state: BreakerState {
        if let lastFailureTime = self.lastFailureTime,
           failureCount > maxFailures &&
           (Date().timeIntervalSince1970 - lastFailureTime) > retryDelay {
            return .halfOpened
        }
        if failureCount == maxFailures {
            return .open
        }
        return .closed
    }
    
    
    // MARK: - Public Instance Attributes For Timer
    
    /// How long the registered work has to finish before throwing an error.
    public let timeout: TimeInterval
    
    /// How long to wait before retrying the registered work after a failure.
    public let retryDelay: TimeInterval
    
    
    // MARK: - Public Instance Attributes For Logging
    
    /// Determines if the behavior of the circuit breaker should be logged.
    public var loggingEnabled: Bool
    
    
    // MARK: - Private Instance Attributes For Circuit Breaker Behavior
    
    /// The last reported error.
    private var lastError: Error?
    
    
    // MARK: - Private Instance Attributes For Timer
    
    /// The timer to use.
    private var scheduler: Scheduler?
    
    /// The time interval for the last failure.
    private var lastFailureTime: TimeInterval?
    
    
    // MARK: - Initializers
    
    /// Initializes an instance of `SGCircuitBreaker`.
    ///
    /// - Parameters:
    ///   - timeout: A `TimeInterval` representing how long the registered work has to finish before throwing
    ///              an error. Defaults to 10.
    ///   - maxFailures: An `Int` representing the number of failures allowed for retrying to performing the
    ///                  registered work before tripping. Defaults to 3.
    ///   - retryDelay: A `TimeInterval` representing how long to wait before retrying the registered work
    ///                 after a failure. Defaults to 2.
    ///   - loggingEnabled: A `Bool` indicating of the behavior of the circuit breaker should be logged.
    ///                     Defaults to `false`.
    public init(timeout: TimeInterval = 10,
                maxFailures: Int = 3,
                retryDelay: TimeInterval = 2,
                loggingEnabled: Bool = false) {
        self.timeout = timeout
        self.maxFailures = maxFailures
        self.retryDelay = retryDelay
        self.loggingEnabled = loggingEnabled
    }
    
    
    // MARK: - Deinitializers
    
    /// Deinitializes an instance of `SGCircuitBreaker`.
    deinit {
        scheduler?.suspend()
        scheduler = nil
    }
}


// MARK: - Public Instance Methods For Beginning
public extension SGCircuitBreaker {
    
    /// Starts the circuit breaker.
    func start() {
        switch state {
        case .open:
            tripCircuit()
        case .halfOpened, .closed:
            beginWork()
        }
    }
}


// MARK: - Public Instance Methods For Registering Success/Failure
public extension SGCircuitBreaker {
    
    /// Reports to the circuit breaker that the registered work was successful.
    func success() {
        log("Registered work was successful. 🎉")
        reset()
        successful?(self)
    }
    
    /// Reports to the circuit breaker that the registered work failed.
    ///
    /// - Parameter error: An `Error` representing the error that occured.
    func failure(error: Error? = nil) {
        log("A failure has been reported! ❌")
        scheduler?.suspend()
        lastError = error
        failureCount += 1
        lastFailureTime = Date().timeIntervalSince1970
        switch state {
        case .open:
            tripCircuit()
            break
        case .halfOpened, .closed:
            startRetryDelayTimer()
            break
        }
    }
}


// MARK: - Public Instance Methods For Resetting
public extension SGCircuitBreaker {
    
    /// Resets the circuit breaker.
    func reset() {
        scheduler?.suspend()
        failureCount = 0
        lastFailureTime = nil
        lastError = nil
        log("Circuit breaker has been reset. 🛠")
    }
}


// MARK: - Private Instance Methods For Timer
private extension SGCircuitBreaker {
    
    /// Starts the timer for when the registered work timed out.
    func startTimeoutTimer() {
        scheduler?.suspend()
        scheduler = Scheduler(startTime: timeout)
        scheduler?.task = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.log("The registered work has timed out! ⏰")
            strongSelf.timedOut?(strongSelf)
            strongSelf.failure()
        }
        scheduler?.resume()
    }
    
    /// Starts the timer for when to wait for retrying to perform the registered work.
    func startRetryDelayTimer() {
        log("Will retry registered work. ⚙️")
        scheduler?.suspend()
        scheduler = Scheduler(startTime: retryDelay)
        scheduler?.task = { [weak self] in
            self?.beginWork()
        }
        scheduler?.resume()
    }
}


// MARK: - Private Instance Methods For Circuit Breaker Behavior
private extension SGCircuitBreaker {
    
    /// Trips the circuit from an error.
    func tripCircuit() {
        log("Circuit breaker has been tripped! 🔥")
        tripped?(self, lastError)
        reset()
    }
    
    /// Begins the work to be performed.
    func beginWork() {
        scheduler?.suspend()
        startTimeoutTimer()
        log("Will begin registered work. 🏗")
        workToPerform?(self)
    }
}


// MARK: - Private Instance Methods For Logging
private extension SGCircuitBreaker {
    
    /// Logs a message to the console.
    ///
    /// - Parameter message: A `String` representing the message to display.
    func log(_ message: String) {
        if !loggingEnabled { return }
        print("SGCircuitBreaker: \(message)")
    }
}
