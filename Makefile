## Makefile
# Commads for setup and running SGCircuitBreaker

.PHONY: help

# Target Rules
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

project:
	swift package generate-xcodeproj

open_xcodeproj:
	open SGCircuitBreaker.xcodeproj

build:
	swift build

clean: ## Cleans the project
	swift package clean

test: 
	swift test

test_linux: ## Complies and run unit tests in Linux using Docker
	docker-compose up

lint:
	swiftlint

# Target Dependencies
all: build project open_xcodeproj ## Complies, generates a new xcodeproj file and opens the project in Xcode

test_local: build test lint ## Complies, run unit tests and lint locally