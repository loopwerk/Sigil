import Foundation
import Sigil
import SymbolKit
import XCTest

final class SigilTests: XCTestCase {
  static var graph: SymbolGraph!

  override class func setUp() {
    let url = Bundle.module.url(forResource: "Saga.symbols", withExtension: "json", subdirectory: "Fixtures")!
    let data = try! Data(contentsOf: url)
    graph = try! JSONDecoder().decode(SymbolGraph.self, from: data)
  }

  func symbol(named name: String) -> SymbolGraph.Symbol {
    SigilTests.graph.symbols.values.first { $0.names.title == name }!
  }

  func symbol(path: String) -> SymbolGraph.Symbol {
    SigilTests.graph.symbols.values.first { $0.pathComponents.joined(separator: ".") == path }!
  }

  // MARK: - escapeHTML

  func testEscapeHTML() {
    XCTAssertEqual(Sigil.escapeHTML("<div>"), "&lt;div&gt;")
    XCTAssertEqual(Sigil.escapeHTML("a & b"), "a &amp; b")
    XCTAssertEqual(Sigil.escapeHTML("\"hi\""), "&quot;hi&quot;")
    XCTAssertEqual(Sigil.escapeHTML("plain"), "plain")
  }

  // MARK: - renderFragment

  func testRenderFragmentKeyword() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .keyword, spelling: "func", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), #"<span class="token keyword">func</span>"#)
  }

  func testRenderFragmentAttribute() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .attribute, spelling: "@discardableResult", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), #"<span class="token attribute atrule">@discardableResult</span>"#)
  }

  func testRenderFragmentTypeIdentifier() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .typeIdentifier, spelling: "String", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), #"<span class="token class-name">String</span>"#)
  }

  func testRenderFragmentGenericParameter() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .genericParameter, spelling: "T", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), #"<span class="token class-name">T</span>"#)
  }

  func testRenderFragmentIdentifier() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .identifier, spelling: "run", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), #"<span class="token function-definition function">run</span>"#)
  }

  func testRenderFragmentText() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .text, spelling: "(", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), "(")
  }

  func testRenderFragmentEscapesHTML() {
    let fragment = SymbolGraph.Symbol.DeclarationFragments.Fragment(kind: .text, spelling: "<T>", preciseIdentifier: nil)
    XCTAssertEqual(Sigil.renderFragment(fragment), "&lt;T&gt;")
  }

  // MARK: - renderDeclaration with real symbols

  func testShortDeclaration() {
    let sym = symbol(named: "FileIO")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">struct</span> <span class="token class-name">FileIO</span>"#
    )
  }

  // swiftformat:disable all
  func testLongDeclaration() {
    let sym = symbol(named: "atomFeed(title:author:baseURL:summary:image:dateKeyPath:)")
    let expected = #"""
<span class="token keyword">func</span> <span class="token function-definition function">atomFeed</span>&lt;<span class="token class-name">Context</span>, <span class="token class-name">M</span>&gt;(
  title: <span class="token class-name">String</span>,
  author: <span class="token class-name">String</span>? = nil,
  baseURL: <span class="token class-name">URL</span>,
  summary: ((<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;) -&gt; <span class="token class-name">String</span>?)? = nil,
  image: ((<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;) -&gt; <span class="token class-name">String</span>?)? = nil,
  dateKeyPath: <span class="token class-name">KeyPath</span>&lt;<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;, <span class="token class-name">Date</span>&gt; = \.lastModified
) -&gt; (<span class="token class-name">Context</span>) -&gt; <span class="token class-name">String</span> <span class="token keyword">where</span> <span class="token class-name">Context</span> : <span class="token class-name">AtomContext</span>, <span class="token class-name">M</span> == <span class="token class-name">Context</span>.<span class="token class-name">M</span>
"""#
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), expected)
  }
  // swiftformat:enable all

  // swiftformat:disable all
  func testSagaInit() {
    let sym = symbol(named: "init(input:output:fileIO:originFilePath:)")
    let expected = #"""
<span class="token keyword">init</span>(
  input: <span class="token class-name">Path</span>,
  output: <span class="token class-name">Path</span> = &quot;deploy&quot;,
  fileIO: <span class="token class-name">FileIO</span> = .diskAccess,
  originFilePath: <span class="token class-name">StaticString</span> = <span class="token keyword">#file</span>
) <span class="token keyword">throws</span>
"""#
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), expected)
  }

  func testCreatePage() {
    let sym = symbol(named: "createPage(_:using:)")
    let expected = #"""
<span class="token attribute atrule">@discardableResult</span>
<span class="token keyword">func</span> <span class="token function-definition function">createPage</span>(
  _ output: <span class="token class-name">Path</span>,
  using renderer: <span class="token attribute atrule">@escaping </span>(<span class="token class-name">PageRenderingContext</span>) <span class="token keyword">async</span> <span class="token keyword">throws</span> -&gt; <span class="token class-name">String</span>
) -&gt; <span class="token class-name">Self</span>
"""#
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), expected)
  }

  func testRegisterLong() {
    let sym = symbol(named: "register(folder:metadata:readers:itemProcessor:filter:claimExcludedItems:itemWriteMode:sorting:writers:)")
    let expected = #"""
<span class="token attribute atrule">@discardableResult</span>
<span class="token keyword">func</span> <span class="token function-definition function">register</span>&lt;<span class="token class-name">M</span>&gt;(
  folder: <span class="token class-name">Path</span>? = nil,
  metadata: <span class="token class-name">M</span>.Type = EmptyMetadata.self,
  readers: [<span class="token class-name">Reader</span>],
  itemProcessor: ((<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;) <span class="token keyword">async</span> -&gt; <span class="token class-name">Void</span>)? = nil,
  filter: <span class="token attribute atrule">@escaping </span>(<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;) -&gt; <span class="token class-name">Bool</span> = { _ in true },
  claimExcludedItems: <span class="token class-name">Bool</span> = true,
  itemWriteMode: <span class="token class-name">ItemWriteMode</span> = .moveToSubfolder,
  sorting: <span class="token attribute atrule">@escaping </span>(<span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;, <span class="token class-name">Item</span>&lt;<span class="token class-name">M</span>&gt;) -&gt; <span class="token class-name">Bool</span> = { $0.date &gt; $1.date },
  writers: [<span class="token class-name">Writer</span>&lt;<span class="token class-name">M</span>&gt;]
) <span class="token keyword">throws</span> -&gt; <span class="token class-name">Self</span> <span class="token keyword">where</span> <span class="token class-name">M</span> : <span class="token class-name">Metadata</span>
"""#
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), expected)
  }

  func testRegisterWrite() {
    let sym = symbol(named: "register(write:)")
    let expected = #"""
<span class="token attribute atrule">@discardableResult</span>
<span class="token keyword">func</span> <span class="token function-definition function">register</span>(write: <span class="token attribute atrule">@escaping </span>(<span class="token class-name">Saga</span>) <span class="token keyword">async</span> <span class="token keyword">throws</span> -&gt; <span class="token class-name">Void</span>) -&gt; <span class="token class-name">Self</span>
"""#
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), expected)
  }
  // swiftformat:enable all

  func testProperty() {
    let sym = symbol(path: "Saga.allItems")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">var</span> allItems: [any <span class="token class-name">AnyItem</span>] { get }"#
    )
  }

  func testTypeProperty() {
    let sym = symbol(named: "diskAccess")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">static</span> <span class="token keyword">var</span> diskAccess: <span class="token class-name">FileIO</span>"#
    )
  }

  func testEnumCase() {
    let sym = symbol(named: "ItemWriteMode.moveToSubfolder")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">case</span> moveToSubfolder"#
    )
  }

  func testTypealias() {
    let sym = symbol(named: "Reader.Converter")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">typealias</span> <span class="token class-name">Converter</span> = (<span class="token class-name">Path</span>) <span class="token keyword">async</span> <span class="token keyword">throws</span> -&gt; (title: <span class="token class-name">String</span>?, body: <span class="token class-name">String</span>, frontmatter: [<span class="token class-name">String</span> : <span class="token class-name">String</span>]?)"#
    )
  }

  func testEnum() {
    let sym = symbol(named: "ItemWriteMode")
    XCTAssertEqual(
      Sigil.renderDeclaration(symbol: sym),
      #"<span class="token keyword">enum</span> <span class="token class-name">ItemWriteMode</span>"#
    )
  }

  func testNoDeclarationFragmentsFallsBackToTitle() throws {
    let json = """
    {
      "kind": {"identifier": "swift.struct", "displayName": "Structure"},
      "identifier": {"precise": "test", "interfaceLanguage": "swift"},
      "pathComponents": ["Test"],
      "names": {"title": "Test<T>"},
      "accessLevel": "public"
    }
    """
    let sym = try JSONDecoder().decode(SymbolGraph.Symbol.self, from: XCTUnwrap(json.data(using: .utf8)))
    XCTAssertEqual(Sigil.renderDeclaration(symbol: sym), "Test&lt;T&gt;")
  }
}
