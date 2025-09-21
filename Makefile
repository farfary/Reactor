# Reactor Makefile
# Simple commands for building and running the Reactor app

.PHONY: build run clean debug help bundle install uninstall

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
	swift build --configuration release

# Build debug version
build-debug:
	swift build --configuration debug

# Build and run the application
run: build
	swift run --configuration release

# Build and run in debug mode with verbose output
debug:
	swift build --configuration debug
	swift run --configuration debug

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Build app bundle
bundle: build
	@echo "Packaging Reactor.app..."
	APP=Reactor.app; \
	mkdir -p release/$$APP/Contents/MacOS; \
	mkdir -p release/$$APP/Contents/Resources; \
	cp .build/*-apple-macosx/release/Reactor release/$$APP/Contents/MacOS/Reactor || cp .build/release/Reactor release/$$APP/Contents/MacOS/Reactor; \
	chmod +x release/$$APP/Contents/MacOS/Reactor; \
	{ \
	  echo '<?xml version="1.0" encoding="UTF-8"?>'; \
	  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'; \
	  echo '<plist version="1.0">'; \
	  echo '<dict>'; \
	  echo '    <key>CFBundleExecutable</key>'; \
	  echo '    <string>Reactor</string>'; \
	  echo '    <key>CFBundleIdentifier</key>'; \
	  echo '    <string>com.reactor.app</string>'; \
	  echo '    <key>CFBundleName</key>'; \
	  echo '    <string>Reactor</string>'; \
	  echo '    <key>LSMinimumSystemVersion</key>'; \
	  echo '    <string>12.0</string>'; \
	  echo '    <key>LSUIElement</key>'; \
	  echo '    <true/>'; \
	  echo '    <key>CFBundlePackageType</key>'; \
	  echo '    <string>APPL</string>'; \
	  echo '</dict>'; \
	  echo '</plist>'; \
	} > release/$$APP/Contents/Info.plist
	@echo "✅ App bundle at release/$$APP"

# Install to /Applications
install: bundle
	@echo "Installing Reactor.app to /Applications (may prompt for password)..."
	cp -R release/Reactor.app /Applications/
	@echo "✅ Installed to /Applications/Reactor.app"

uninstall:
	rm -rf /Applications/Reactor.app
	@echo "🗑️  Removed /Applications/Reactor.app"