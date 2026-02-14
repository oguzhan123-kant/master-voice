.PHONY: dev cli test build

dev:
	./scripts/run-app.sh

cli:
	swift run master-voice-cli

test:
	swift test

build:
	swift build
