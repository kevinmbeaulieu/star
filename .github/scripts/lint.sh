#!/bin/bash

set -e -u -o pipefail

sh .github/scripts/install_swiftlint.sh
sh .github/scripts/install_swiftformat.sh

swiftlint lint --quiet --strict .
swiftformat --lint .
