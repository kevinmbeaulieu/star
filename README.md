[![Build Status](https://badgen.net/github/checks/kevinmbeaulieu/star)](https://github.com/kevinmbeaulieu/star/actions/workflows/ci.yml?query=branch%3Amain)
[![SPM Latest Version](https://img.shields.io/github/v/release/kevinmbeaulieu/star?label=SPM)](https://swiftpackageindex.com/kevinmbeaulieu/star)
[![License](https://img.shields.io/github/license/kevinmbeaulieu/star?color=important)](https://github.com/kevinmbeaulieu/star/blob/main/LICENSE)

# Swift Type Adoption Reporter (STAR)

Generate reports on how frequently specified Swift types are being used in your iOS codebase with a simple command-line interface.

## Install

```
$ cd star
$ make install
```

## Usage

```
$ star --types Avatar Button Color Pill --files ./

Avatar used 27 times.
Button used 167 times.
Color used 2711 times.
Pill used 9 times.
```

To report on types which are in a separate module, specify a `--moduleName`. This will ensure that  references like `Thumbprint.Button()` are captured too.

```
$ star --types Avatar Button Color Pill --files ./ --module Thumbprint

Avatar used 30 times.
Button used 182 times.
Color used 2786 times.
Pill used 11 times.
```

### Options

```
USAGE: star [--types <types> ...] [--module <module>] [--format <format>] [--files <files> ...] [--includeTypeInheritance] [--verbose]

OPTIONS:
  -t, --types <types>     List of types on which to report
  -m, --module <module>   Name of module containing types, to ensure types referenced by <module name>.<type name> are counted
  -f, --format <format>   Output format (humanReadable|json) (default: humanReadable)
  --files <files>         Paths in which to look for Swift source
  --includeTypeInheritance
                          Include subclass and protocol conformance declarations in usage counts
  -v, --verbose           Print additional information about source as it is parsed
  -h, --help              Show help information.
```

## How it Works

STAR uses [SwiftSyntax](https://github.com/apple/swift-syntax) to traverse the AST and find references to the specified identifiers.
Since STAR operates on the untyped AST, usage reports may contain imperfect information when linking a reference to its identifier would require full type checking.

The reporter attempts to provide as useful information as possible, so some types of references are intentionally filtered out. For example, the line of code
```
let foo: UIView = UIView()
```
technically includes two nodes in the AST for the `UIView` identifier: one in the type annotation, and one in the constructor call. For most business uses, though, it is preferable to only count this line as a single use of `UIView`. Therefore, type annotations are ignored by STAR.

Some other examples of intentionally ignored references are code comments, class/struct/extension/etc. declarations, and inner classes within components (e.g., `MyComponent.SomeInnerClass` will match neither `MyComponent`, nor `SomeInnerClass`).

## Uninstall

```
$ cd star
$ make uninstall
```

## Importing into another Swift package

In addition to the command-line executable `star`, STAR's core functionality is also available through Swift Package Manager as the static library `STARLib`. To use `STARLib` in your Swift package, add the following to your Package.swift:
```
let package = Package(
    ...
    dependencies: [
        ...
        .package(name: "SwiftTypeAdoptionReporter", url: "https://github.com/thumbtack/star.git", <version (e.g., `.upToNextMinor(from: "3.0.0")`)>),
    ],
    targets: [
        .target(
            ...
            dependencies: [
                ...
                .product(name: "STARLib", package: "SwiftTypeAdoptionReporter"),
            ]
        ),
    ]
)
```

## Contributing

If you have ideas to make STAR more useful, open an issue or submit a pull request! See below for instructions on building/testing locally.

```
$ git clone git@github.com/kevinmbeaulieu/star.git
$ cd star
$ xed .
```

### To build & run locally:
```
$ swift run star ...
```

Passing in the `--verbose` argument will print out additional information which can be useful for debugging.

### To run test suite:

#### From command line:
```
$ swift test
```

#### With Xcode:
1. Open project in Xcode with `xed .`
3. In Xcode, **Product -> Test**
