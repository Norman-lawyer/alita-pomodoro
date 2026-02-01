#!/bin/bash

set -e

echo "🍅 Lolita Pomodoro - Setup Script"
echo "=================================="

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "📦 XcodeGen not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "❌ Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

echo "🔧 Generating Xcode project..."
cd "$(dirname "$0")"
xcodegen generate

echo "✅ Xcode project generated successfully!"
echo ""
echo "📦 Building the app..."
xcodebuild -project LolitaPomodoro.xcodeproj \
    -scheme LolitaPomodoro \
    -configuration Release \
    -destination "platform=macOS" \
    build

echo ""
echo "✅ Build complete!"
echo ""
echo "📍 App location: build/Release/LolitaPomodoro.app"
echo ""
echo "💡 To run the app:"
echo "   open build/Release/LolitaPomodoro.app"
echo ""
echo "📋 To install to Applications:"
echo "   cp -r build/Release/LolitaPomodoro.app /Applications/"
