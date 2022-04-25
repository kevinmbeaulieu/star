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

@testable import STARLib
import XCTest

final class SwiftTypeAdoptionReporterTests: XCTestCase {
    /// *Do* count calls to constructors iff .constructorCall included
    func testInitVar() {
        let sourceString = "let myView = UIView()"
        verify(
            expected: ["UIView": 1],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count explicit type annotations on a variable
    func testInitVarWithTypeAnnotation() {
        let sourceString = "let myView: UIView = UIView()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count explicit type annotations on a variable
    func testDeclareVarThenSet() {
        let sourceString =
            """
            let myView: UIView
            myView = UIView()
            """
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count calls to array-type constructors iff .constructorCall included
    func testInitArrayTypeVar() {
        let sourceString = "let myViews = [UIView]()"
        verify(
            expected: ["UIView": 1],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count explicit type annotations on an array-type variable
    func testInitArrayTypeVarWithTypeAnnotation() {
        let sourceString = "let myViews: [UIView] = [UIView]()"
        let expected = ["UIView": 1]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count subclasses iff .typeInheritance included
    func testDeclareSubclass() {
        let sourceString =
            """
            class MyView: UIView {
            }
            """
        verify(
            expected: ["UIView": 1],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.typeInheritance])
            }
        )
    }

    /// *Do* count protocol conformance iff .typeInheritance is included
    func testProtocolConformance() {
        let sourceString =
            """
            protocol MyProtocol {}
            class Foo: UIView, MyProtocol {}
            class Bar: MyProtocol {}
            """
        verify(
            expected: ["MyProtocol": 2],
            for: sourceString
        )
        verify(
            expected: ["MyProtocol": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.typeInheritance])
            }
        )
    }

    /// *Do not* count declaration of the component itself
    func testDeclareSameNameClass() {
        let sourceString =
            """
            class UIView {
            }
            """
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* include references inside the component itself
    func testReferenceInsideSameNameClassDelaraction() {
        let sourceString =
            """
            class UIView {
                let _ = UILabel()
            }
            """
        let expected = ["UIView": 0, "UILabel": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* include references inside non-component class
    func testReferenceInsideOtherClass() {
        let sourceString =
            """
            class UIView {
                let _ = UILabel()
            }
            """
        verify(
            expected: ["UILabel": 1],
            for: sourceString
        )
        verify(
            expected: ["UILabel": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count declaraction of the component itself
    func testDeclareSameNameStruct() {
        let sourceString =
            """
            struct UIView {
            }
            """
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count declaraction of extensions on the component
    func testDeclareSameNameExtension() {
        let sourceString =
            """
            extension UIView {
            }
            """
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count constructor calls relative to a provided module name iff .constructorCall included
    func testConstructorCallWithModuleName() {
        let sourceString = "let _ = MyModule.Foo()"
        let moduleName = "MyModule"
        verify(
            expected: ["Foo": 1],
            for: sourceString,
            moduleName: moduleName
        )
        verify(
            expected: ["Foo": 0],
            for: sourceString,
            moduleName: moduleName,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count constructor calls relative to a containing module/class if no module name provided
    func testNamespacedFunctionCallWithoutModuleName() {
        let sourceString = "let _ = Foo.Bar()"
        let expected = ["Bar": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count function calls relative to a containing module/class other than the provided module name
    func testNamespacedFunctionCallInNonModule() {
        let sourceString = "let _ = NotMyModule.Foo()"
        let expected = ["Foo": 0]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do* count property references relative to a provided module name iff .staticPropertyReference included
    func testPropertyReferenceWithModuleName() {
        let sourceString = "let _ = MyModule.Foo.bar"
        let moduleName = "MyModule"
        verify(
            expected: ["Foo": 1],
            for: sourceString,
            moduleName: moduleName
        )
        verify(
            expected: ["Foo": 0],
            for: sourceString,
            moduleName: moduleName,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.staticPropertyReference])
            }
        )
    }

    /// *Do* count property references with no module name iff .staticPropertyReference included
    func testPropertyReference() {
        let sourceString = "let _ = Foo.bar"
        verify(
            expected: ["Foo": 1],
            for: sourceString
        )
        verify(
            expected: ["Foo": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.staticPropertyReference])
            }
        )
    }

    /// *Do not* count property references relative to a containing module/class if no module name provided
    func testNamespacedPropertyReferenceWithoutModuleName() {
        let sourceString = "let _ = Foo.Bar.baz"
        let expected = ["Bar": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count property references relative to a containing module/class other than the provided module name
    func testNamespacedPropertyReferenceInNonModule() {
        let sourceString = "let _ = NotMyModule.Foo.bar"
        let expected = ["Foo": 0]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do not* count property references relative to the provided module name in addition to some other module/class
    func testPropertyReferenceInModuleInNonModule() {
        let sourceString = "let _ = NotMyModule.MyModule.Foo.bar"
        let expected = ["Foo": 0]
        let moduleName = "MyModule"
        verify(expected: expected, for: sourceString, moduleName: moduleName)
    }

    /// *Do* count references inside another function call
    func testFunctionArgument() {
        let sourceString = "Foo(child: Foo())"
        verify(
            expected: ["Foo": 2],
            for: sourceString
        )
        verify(
            expected: ["Foo": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count contents of a comment
    func testComment() {
        let sourceString = "// This is a comment about UIView"
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count contents of a string
    func testString() {
        let sourceString = "\"UIView\""
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count references in string interpolation
    func testStringInterpolation() {
        let sourceString = "\"\\(UIView())\""
        verify(
            expected: ["UIView": 1],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do not* count type casting
    func testTypeCast() {
        let sourceString = "foo as UIView"
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count optional type casting
    func testOptionalTypeCasting() {
        let sourceString = "foo as? UIView"
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do not* count force casting
    func testForceCasting() {
        let sourceString = "foo as! UIView"
        let expected = ["UIView": 0]
        verify(expected: expected, for: sourceString)
    }

    /// *Do* count function calls that are arguments to a chained function call
    func testFunctionCallArgumentInChainedFunctionCall() {
        let sourceString = "foo.bar(UIView()).buzz(UIView()).baz(UIView())"
        verify(
            expected: ["UIView": 3],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.constructorCall])
            }
        )
    }

    /// *Do* count property references that are arguments to a chained function call iff .staticPropertyReference included
    func testPropertyReferenceArgumentInChainedFunctionCall() {
        let sourceString = "foo.bar(UIView.someProp).buzz(UIView.someProp).baz(UIView.someProp)"
        verify(
            expected: ["UIView": 3],
            for: sourceString
        )
        verify(
            expected: ["UIView": 0],
            for: sourceString,
            setUp: {
                $0.includeSyntax = $0.includeSyntax.subtracting([.staticPropertyReference])
            }
        )
    }

    // MARK: - Private

    private func verify(expected: [String: Int],
                        types: [String]? = nil,
                        for sourceString: String,
                        moduleName: String? = nil,
                        setUp: ((FastStrategy) -> Void)? = nil,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let types = types ?? expected.map({ key, _ in key })
        assert(!types.isEmpty, "If `expected` is an empty dictionary, a list of component identifiers to search for must be passed explicitly in the `types` argument. Otherwise the test won't really be testing anything.", file: file, line: line) // swiftlint:disable:this line_length

        do {
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let temporaryFile = temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString, isDirectory: false)
            try sourceString.write(to: temporaryFile, atomically: false, encoding: .utf8)

            let strategy = FastStrategy(
                types: types,
                moduleName: moduleName,
                includeSyntax: Set(SyntaxType.allCases),
                paths: [temporaryFile]
            )

            setUp?(strategy)

            let actual = (try strategy.findUsageCounts()).mapValues({ $0.usageCount })
            XCTAssertEqual(expected, actual, file: file, line: line)
        } catch {
            XCTFail("Failed with error \(String(describing: error))", file: file, line: line)
        }
    }
}
