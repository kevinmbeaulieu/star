#!/bin/bash

set -e -u -o pipefail

swiftlint lint --quiet
swiftformat --lint .
