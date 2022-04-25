#!/bin/bash

# Installs the SwiftFormat package if it's not already installed.

set -e

# Check if already installed.
if type swiftformat > /dev/null 2>&1; then
    exit 0
fi

# Attempted to install from Homebrew.
brew update && brew install swiftformat

if type swiftformat > /dev/null 2>&1; then
    exit 0
fi

# If Homebrew installation failed, compile from source and install.
echo "Failed to install SwiftFormat from Homebrew. Compiling from source..." &&
swiftformat_repo_path=$(mktemp) &&
git clone https://github.com/nicklockwood/SwiftFormat.git $swiftformat_repo_path &&
cd $swiftformat_repo_path &&
git submodule update --init --recursive &&
swift build -c release &&
install .build/release/swiftformat /usr/local/bin
