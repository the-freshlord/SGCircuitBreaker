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

/// A class responsible for scheduling a task after some given time.
final class Scheduler {
    
    // MARK: - Public Instance Attributes
    
    /// The task to run after the timer's event handler is fired.
    var task: (() -> Void)?
    
    
    // MARK: - Private Instance Attributes For Timer.
    
    /// An enum that keeps track of the state of the timer.
    ///
    /// - suspended: The timer is not being used.
    /// - resumed: The timer is being used.
    private enum TimerState {
        case suspended
        case resumed
    }
    
    /// The current state of the timer.
    private var timerState: TimerState = .suspended
    
    /// The time to start the task.
    private let startTime: TimeInterval
    
    /// The timer to use.
    private lazy var timer: DispatchSourceTimer = {
        let dispatchTimer = DispatchSource.makeTimerSource()
        let time: DispatchTime = .now() + startTime
        dispatchTimer.schedule(deadline: time)
        dispatchTimer.setEventHandler { [weak self] in
            self?.task?()
        }
        return dispatchTimer
    }()
    
    
    // MARK: - Initializers
    
    /// Initializes an instance of `Scheduler`.
    ///
    /// - Parameter startTime: A `TimeInterval` representing when to start the task.
    init(startTime: TimeInterval) {
        self.startTime = startTime
    }
    
    
    // MARK: - Deintializers
    
    /// Deinitializes an instance of `Scheduler`.
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        timer.resume()
        task = nil
    }
}


// MARK: - Public Instance Methods For Resume/Suspend
extension Scheduler {
    
    /// Resumes the timer to schedule the task.
    func resume() {
        if timerState == .resumed { return }
        timerState = .resumed
        timer.resume()
    }
    
    /// Susupends the timer.
    func suspend() {
        if timerState == .suspended { return }
        timerState = .suspended
        timer.suspend()
    }
}
