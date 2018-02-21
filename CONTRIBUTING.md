# Contributing to SGCircuitBreaker

First off - thank you!!!

## The goal

SGCircuitBreaker is designed to be simple and easy to use. Its a light weight circuit breaker that can be used in a variety of projects.

## Branching

If you would like to fork SGCircuitBreaker, feel free to do so. If you would like to contribute to SGCircuitBreaker, please clone the repository, make a branch, and submit a PR from that branch. This is to allow CI to do its job properly with access to [Package-Builder](https://github.com/IBM-Swift/Package-Builder).

## Pull Requests

Please submit any feature requests or bug fixes as a pull request.

Please make sure that all pull requests have the following:

- a descriptive title
- a meaningful body of text to explain what the PR does
- if it fixes a pre-existing issue, include the issue number in the body of text

Pushing directly to master is disallowed.

## Running locally

To run SGCircuitBreaker locally, please follow these steps:

- Clone the repository
- Then do `$ make all`.

To run the test suite locally:

- `$ make test_local`

To run the test suite in a Linux container:

- `$ make test_linux`

Note that this requires [Docker](https://www.docker.com/) to be installed.

To see all available commands:

- `$ make`

**Thanks for contributing! :100:**