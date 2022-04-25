#!/bin/bash

# Installs the SwiftFormat package.
# Tries to install from Homebrew, but if that fails just recompiles from source.

set -e

brew update && brew install swiftformat

if ! type swiftformat > /dev/null 2>&1; then
    echo "Failed to install SwiftFormat from Homebrew. Compiling from source..." &&
    swiftformat_repo_path=$(mktemp) &&
    git clone https://github.com/nicklockwood/SwiftFormat.git $swiftformat_repo_path &&
    cd $swiftformat_repo_path &&
    git submodule update --init --recursive &&
    swift build -c release &&
    install .build/release/swiftformat /usr/local/bin
fi
