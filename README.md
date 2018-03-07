<p align="center">
	<img src="./Assets/sgcircuitbreakerLogo.jpg">
</p>

<p align="center">
    <a href="https://travis-ci.org/eman6576/SGCircuitBreaker.svg?branch=master">
        <img src="https://travis-ci.org/eman6576/SGCircuitBreaker.svg?branch=master" alt="Travis CI Status">
    </a>
    <a href="https://codecov.io/gh/eman6576/SGCircuitBreaker">
        <img src="https://codecov.io/gh/eman6576/SGCircuitBreaker/branch/master/graph/badge.svg" alt="CodeCov">
    </a>
    <a href="https://swift.org/">
        <img src="https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat" alt="CodeCov">
    </a>
	<a href="https://cocoapods.org/pods/SGCircuitBreaker">
		<img src="https://img.shields.io/cocoapods/v/SGSwiftyBind.svg" alt="Pods Version">
	</a>
	<a href="https://github.com/Carthage/Carthage">
		<img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage Compatible">
	</a>
	<a href="https://swift.org/package-manager/">
		<img src="https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat" alt="Swift PM Compatible">
	</a>
	<a href="https://github.com/eman6576/SGCircuitBreaker/blob/master/LICENSE">
		<img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
	</a>
    <a href="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20Linux-lightgrey.svg">
		<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20Linux-lightgrey.svg" alt="Platforms">
	</a>
	<a href="https://github.com/RichardLitt/standard-readme">
		<img src="https://img.shields.io/badge/standard--readme-OK-green.svg" alt="Standard README Compliant">
	</a>
</p>

----------------

A Swift implementation of the Circuit Breaker design pattern

## Table of Contents

- [Background](#background)
- [Platforms](#platforms)
- [Install](#install)
- [Usage](#usage)
- [API](#api)
- [Contribute](#contribute)
- [License](#license)

## Background

This is a light weigth implementation of the [Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html) design pattern done in Swift. A circuit breaker is useful for when performing some kind of work that could fail and wanting to repeat the work based on a given configuration or threshold. When the threshold is met, the circuit breaker will trip, preventing unnecessary load until the breaker resets after a timeout. This implementation provides an easy to use way of monitoring timeouts and supporting retry logic.

## Platforms

* iOS: 9.0 and greater
* macOS: 10.9 and greater
* Linux

## Install

### CocoaPods

You can use [CocoaPods](https://cocoapods.org) to install `SGCircuitBreaker` by adding it to your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks

target 'MyApp' do
    pod 'SGCircuitBreaker'
end
```

### Carthage

You can use [Carthage](https://github.com/Carthage/Carthage) to install `SGCircuitBreaker` by adding it to your `Cartfile`:

```bash
github "eman6576/SGCircuitBreaker"
```

### Swift Package Manager

You can use [Swift Package Manager](https://swift.org/package-manager/) to install `SGCircuitBreaker` by adding the proper description to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/eman6576/SGCircuitBreaker.git", .upToNextMajor(from: "1.1.4"))
    ],
    targets: [
        .target(
            name: "YOUR_TARGET_NAME",
            dependencies: [
                "SGCircuitBreaker"
            ]
        )
    ]
)
```

## Usage

### Initialization

To access the available data types, import `SGCircuitBreaker` into your project like so:

```swift
import SGCircuitBreaker
```

We can instantiate an instance of `SGCircuitBreaker` in one of two ways:

```swift
let circuitBreaker = SGCircuitBreaker()
```

using the default configuration or like

```swift
let circuitBreaker = SGCircuitBreaker(
    timeout: 20,
    maxFailures: 4,
    retyDelay: 3
)
```

### Functionality

With a circuit breaker instance, we need to register the work that needs to be performed:

```swift
circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
    self?.mockService.call { (data, error) in
        guard error == nil else {
            circuitBreaker.failure(error: error)
            return
        }
        circuitBreaker.success()
    }
}
```

Here we register the work that needs to be performed. The work is calling an asynchronous method on `mockService` that could fail. In the closure for the method `call`, we check if an error occured. If it did, we report to the circuit breaker that the work failed by calling `circuitBreaker.failure(error: error)` and pass the error. This will check if the maximum amount of failures have been met or not. If the maximum amount hasn't been met, then the circuit breaker would wait for a certain amount of time before trying the work again. The circuit breaker would be in the `halfOpened` state. If the maximum amount of failures are met, then the circuit breaker trips. If an error didn't occur, then we report to the circuit breaker that the work was successful by calling `circuitBreaker.success()`. This will reset the circuit breaker to its initial state of `closed`.

Now what happens if the circuit breaker trips. We want to be able to handle this and perform any error handling logic neccessary that will not break our application. We can register how to handle the circuit breaker tripping like so:

```swift
circuitBreaker.tripped = { (circuitBreaker, error) in
    print("Error occured with breaker: \(error)")
}
```

Here we register a handler for when the circuit breaker trips. An `Error?` is passed that represents the last error that was reported. At this point, the circuit breaker is in the `open` state.

There might be some cases where you need to know if the circuit breaker was successful. This also means when a success is reported to the circuit breaker. We can register a handler like so:

```swift
circuitBreaker.successful { (circuitBreaker) in
    print("Circuit breaker was successful")
}
```

We can also handle when the circuit breaker reaches the set timeout. We can use it to cancel the registered work like so:

```swift
circuitBreaker.timedOut = { [weak self] (circuitBreaker) in
    print("Timeout reached")
    self?.mockService.cancel()
}
```

Once we have set up our handlers, we need to start the circuit breaker like so:

```swift
circuitBreaker.start()
```

Here is a full example of how the circuit breaker would be used:

```swift
let circuitBreaker = SGCircuitBreaker(
    timeout: 20,
    maxFailures: 4,
    retyDelay: 3
)

circuitBreaker.workToPerform = { [weak self] (circuitBreaker) in
    self?.mockService.call { (data, error) in
        guard error == nil else {
            circuitBreaker.failure(error: error)
            return
        }
        circuitBreaker.success()
    }
}

circuitBreaker.tripped = { (circuitBreaker, error) in
    print("Error occured with breaker: \(error)")
}

circuitBreaker.successful { (circuitBreaker) in
    print("Circuit breaker was successful")
}

circuitBreaker.timedOut = { [weak self] (circuitBreaker) in
    print("Timeout reached")
    self?.mockService.cancel()
}

circuitBreaker.start()
```

### Initial Configuration

`SGCircuitBreaker` can be configured with three parameters:

* `timeout`: A `TimeInterval` representing how long the registered work has to finish before throwing an error. Defaults to 10.
* `maxFailures`: An `Int` representing the number of failures allowed for retrying to performing the registered work before tripping. Defaults to 3.
* `retryDelay`: A `TimeInterval` representing how long to wait before retrying the registered work after a failure. Defailts to 2.

### Public Interface

`SGCircuitBreaker` contains some public methods and attributes:

#### Methods

* `start()`: Starts the circuit breaker.
* `success()`: Reports to the circuit breaker that the registered work was successful.
* `failure(error: Error? = nil)`: Reports to the circuit breaker that the registered work failed.
* `reset()`: Resets the circuit breaker.

#### Attributes

* `failureCount`: Current number of failures.
* `state`: The current state of the circuit breaker. Can be either `open`, `halfOpened`, or `closed`.

### Logging

`SGCircuitBreaker` can log to the console different events that occur within the circuit breaker. By default, this is not enabled. If you would like to enable it you can enable it when creating an instance like so:

```swift
let circuitBreaker = SGCircuitBreaker(loggingEnabled: true)
```

You can also change this property at anytime as well:

```swift
circuitBreaker.loggingEnabled = true
```

When an event is logged, this is what it would look like in the console:

```
SGCircuitBreaker: Registered work was successful. 🎉
```

### Tests
See [SGCircuitBreakerTests.swift](https://github.com/eman6576/SGCircuitBreaker/blob/master/Tests/SGCircuitBreakerTests/SGCircuitBreakerTests.swift) for some examples on how to use it.

## Contribute

See [the contribute file](CONTRIBUTING.md)!

PRs accepted.

Small note: If editing the Readme, please conform to the [standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## Maintainers

Manny Guerrero [![Twitter Follow](https://img.shields.io/twitter/follow/SwiftyGuerrero.svg?style=social&label=Follow)](https://twitter.com/SwiftyGuerrero) [![GitHub followers](https://img.shields.io/github/followers/eman6576.svg?style=social&label=Follow)](https://github.com/eman6576)

## License

[MIT © Manny Guerrero.](https://github.com/eman6576/SGCircuitBreaker/blob/master/LICENSE)