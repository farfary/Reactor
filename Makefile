# Reactor Makefile
# Simple commands for building and running the Reactor app

.PHONY: build run clean debug help

# Default target
help:
	@echo "Reactor - macOS Menubar Process Monitor"
	@echo ""
	@echo "Available commands:"
	@echo "  make build    - Build the application"
	@echo "  make run      - Build and run the application"
	@echo "  make debug    - Build and run in debug mode"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make help     - Show this help message"

# Build the application
build:
	swift build

# Build and run the application
run: build
	swift run

# Build and run in debug mode with verbose output
debug:
	swift build --configuration debug
	swift run --configuration debug

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Install (copy to Applications folder) - requires admin
install: build
	@echo "Note: Manual installation required"
	@echo "Copy the built binary from .build/debug/Reactor to your desired location"