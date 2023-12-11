// Copyright 2020 Thumbtack, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SwiftParser
import SwiftSyntax

public class FastStrategy: SyntaxVisitor, Strategy {
    public var includeSyntax: Set<SyntaxType>

    public init(types: [String],
                moduleName: String?,
                includeSyntax: Set<SyntaxType>,
                paths: [URL],
                viewMode: SyntaxTreeViewMode = .sourceAccurate,
                verbose: Bool = false) {
        self.types = types
        self.moduleName = moduleName
        self.includeSyntax = includeSyntax
        self.paths = paths
        self.verbose = verbose
        super.init(viewMode: viewMode)
    }

    public func findUsageCounts() throws -> [String: TypeUsage] {
        fileCounts = [:]
        usageCounts = [:]

        for path in paths {
            try visit(fileOrDirectory: path)
        }

        var typeUsages: [String: TypeUsage] = [:]
        for type in types {
            typeUsages[type] = TypeUsage(
                fileCount: fileCounts[type]?.count ?? 0,
                usageCount: usageCounts[type] ?? 0
            )
        }

        if verbose {
            for type in types {
                guard let files = fileCounts[type] else { continue }

                print("\(type) used in the following files:")
                files
                    .map({ " \($0.path)" })
                    .forEach { print($0) }
            }
        }

        return typeUsages
    }

    enum Error: Swift.Error, CustomStringConvertible {
        case noSuchFileOrDirectory(URL)

        var description: String {
            switch self {
            case let .noSuchFileOrDirectory(url):
                return "No such file or directory: \(url.path)"
            }
        }
    }

    // MARK: - SyntaxVisitor

    override public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        if includeSyntax.contains(.constructorCall),
           case let .identifier(identifier) = token.tokenKind,
           types.contains(identifier) {
            increment(identifier, token: token)
        }

        return .skipChildren
    }

    override public func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let base = node.base else { return .visitChildren }

        if let baseIdentifierExpr = base.as(DeclReferenceExprSyntax.self) {
            if case let .identifier(baseIdentifier) = baseIdentifierExpr.baseName.tokenKind {
                if includeSyntax.contains(.staticPropertyReference),
                   types.contains(baseIdentifier) {
                    increment(baseIdentifier, token: baseIdentifierExpr.baseName)
                    return .skipChildren
                }

                if includeSyntax.contains(.constructorCall),
                   let moduleName = moduleName,
                   baseIdentifier == moduleName,
                   case let .identifier(identifier) = node.declName.baseName.tokenKind,
                   types.contains(identifier) {
                    increment(identifier, token: node.declName.baseName)
                    return .skipChildren
                }
            }

            return .skipChildren

        } else if let baseMemberAccessExpr = base.as(MemberAccessExprSyntax.self) {
            if includeSyntax.contains(.staticPropertyReference),
               let moduleName = moduleName,
               let innerBaseIdentifierExpr = baseMemberAccessExpr.base?.as(DeclReferenceExprSyntax.self),
               case let .identifier(innerBaseIdentifier) = innerBaseIdentifierExpr.baseName.tokenKind,
               innerBaseIdentifier == moduleName,
               case let .identifier(innerIdentifier) = baseMemberAccessExpr.declName.baseName.tokenKind,
               types.contains(innerIdentifier) {
                increment(innerIdentifier, token: baseMemberAccessExpr.declName.baseName)
                return .skipChildren
            }

            return .skipChildren
        }

        return .visitChildren
    }

    override public func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
        if let moduleName = moduleName, let baseToken = node.baseType.as(IdentifierTypeSyntax.self)?.name {
            switch baseToken.tokenKind {
            case let .identifier(baseTokenIdentifier) where moduleName == baseTokenIdentifier:
                return .visitChildren
            default:
                return .skipChildren
            }
        }

        return .skipChildren
    }

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.name.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.name.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let typeIdentifier = node.extendedType.as(IdentifierTypeSyntax.self) {
            switch typeIdentifier.name.tokenKind {
            case let .identifier(identifier) where types.contains(identifier):
                if verbose {
                    print("Skipping contents of extension of \(identifier)")
                }

                return .skipChildren
            default:
                return .visitChildren
            }
        }

        return .visitChildren
    }

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        switch node.name.tokenKind {
        case let .identifier(identifier) where types.contains(identifier):
            if verbose {
                print("Skipping contents of \(identifier)'s implementation")
            }

            return .skipChildren
        default:
            return .visitChildren
        }
    }

    override public func visit(_: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: TypeExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        if includeSyntax.contains(.typeInheritance) {
            for inheritedType in node.inheritedTypes {
                guard let typeIdentifier = inheritedType.type.as(IdentifierTypeSyntax.self) else { continue }

                switch typeIdentifier.name.tokenKind {
                case let .identifier(identifier) where types.contains(identifier):
                    increment(identifier, token: typeIdentifier.name)

                default:
                    break
                }
            }
        }

        return .skipChildren
    }

    override public func visit(_: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override public func visit(_: AsExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    // MARK: - Private

    private let types: [String]
    private let moduleName: String?
    private let paths: [URL]
    private let verbose: Bool
    private var fileCounts: [String: Set<URL>] = [:]
    private var usageCounts: [String: Int] = [:]
    private var currentFile: URL?

    /**
     * - Parameters:
     *   - fileOrDirectory: Path of file/directory to parse.
     *   - reporter: Reporter in which to store report.
     */
    private func visit(fileOrDirectory: URL) throws {
        let isDirectoryPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        guard FileManager.default.fileExists(atPath: fileOrDirectory.path, isDirectory: isDirectoryPointer) else {
            throw Error.noSuchFileOrDirectory(fileOrDirectory)
        }

        if isDirectoryPointer.pointee.boolValue {
            let directory = fileOrDirectory

            let fileEnumerator = FileManager.default.enumerator(atPath: directory.path)
            while let fileName = fileEnumerator?.nextObject() as? String {
                // Skip non-Swift files
                if !fileName.hasSuffix(".swift") { continue }

                let file = directory.appendingPathComponent(fileName, isDirectory: false)

                if !FileManager.default.fileExists(atPath: file.path, isDirectory: isDirectoryPointer) || isDirectoryPointer.pointee.boolValue {
                    // Files inside subdirectories will already be included in fileEnumerator.
                    // Recursively calling visit(fileOrDirectory:with:) on them here would result
                    // in duplicated counts.
                    continue
                }

                try visit(file: file)
            }
        } else {
            let file = fileOrDirectory
            try visit(file: file)
        }
    }

    /**
     * - Parameters:
     *   - file: Path of file to parse.
     *   - reporter: Reporter in which to store report.
     */
    private func visit(file: URL) throws {
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw Error.noSuchFileOrDirectory(file)
        }

        currentFile = file

        let source: String = try String(contentsOf: file)
        let parsedSource = Parser.parse(source: source)
        walk(parsedSource)
    }

    private func increment(_ identifier: String, token: TokenSyntax) {
        if verbose {
            print(token.verboseDescription)
        }

        usageCounts[identifier] = (usageCounts[identifier] ?? 0) + 1

        if let currentFile = currentFile {
            if fileCounts[identifier] != nil {
                fileCounts[identifier]?.insert(currentFile)
            } else {
                fileCounts[identifier] = [currentFile]
            }
        }
    }
}

// MARK: - TokenSyntax

private extension TokenSyntax {
    var verboseDescription: String {
        // (Printing info about ancestor is typically more useful than printing the token syntax node itself.)
        let node: CustomStringConvertible = parent?.parent?.parent ?? self

        var output = ""
        output += node.description
        output += "\n"
        output += String(describing: type(of: node))
        output += "\n-----------------"
        return output
    }
}
