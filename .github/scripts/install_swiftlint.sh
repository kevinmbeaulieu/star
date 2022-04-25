#!/bin/bash

# Installs the SwiftLint package if it's not already installed.

set -e

# Check if already installed.
if type swiftlint > /dev/null 2>&1; then
    exit 0
fi

# Attempted to install from Homebrew.
brew update && brew install swiftlint

if type swiftlint > /dev/null 2>&1; then
    exit 0
fi

# If Homebrew installation failed, compile from source and install.
echo "Failed to install SwiftLint from Homebrew. Compiling from source..." &&
swiftlint_repo_path=$(mktemp swiftlint.XXXX) &&
git clone https://github.com/realm/SwiftLint.git $swiftlint_repo_path &&
cd $swiftlint_repo_path &&
git submodule update --init --recursive &&
make install
