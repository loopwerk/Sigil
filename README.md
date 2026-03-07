# Sigil

Render Swift [SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit) declarations as syntax-highlighted HTML.

Takes the declaration fragments from a symbol graph (as produced by the SwiftPM command `swift package dump-symbol-graph`) and turns them into HTML with [Prism](https://prismjs.com)-compatible CSS classes, with smart multi-line formatting for long function signatures.

## Installation

Add Sigil as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/loopwerk/Sigil", from: "1.0.0"),
```

Then add it to your target:

```swift
.target(name: "MyApp", dependencies: ["Sigil"]),
```

## Usage

```swift
import Sigil
import SymbolKit

// Decode a symbol graph
let data = try Data(contentsOf: symbolGraphURL)
let graph = try JSONDecoder().decode(SymbolGraph.self, from: data)

// Render a symbol's declaration
for (_, symbol) in graph.symbols {
  let html = Sigil.renderDeclaration(symbol: symbol)
  // <span class="token keyword">func</span> <span class="token function-definition function">run</span>(...)
}
```

## CSS classes

Sigil uses Prism-compatible token classes:

| Fragment kind | CSS class |
|---|---|
| Keywords (`func`, `class`, `let`, ...) | `token keyword` |
| Attributes (`@discardableResult`, ...) | `token attribute atrule` |
| Type identifiers, generic parameters | `token class-name` |
| Type definition names (`struct Foo`, `enum Bar`, ...) | `token class-name` |
| Function/method definition names (`func run`, ...) | `token function-definition function` |
| Property, variable, and enum case names | _(no wrapper)_ |
| Text (punctuation, whitespace) | _(no wrapper)_ |

When rendering a full declaration via `renderDeclaration`, Sigil uses the symbol's kind to determine how `.identifier` fragments are highlighted — matching what Prism itself would produce for equivalent Swift code.

## API

### `Sigil.renderDeclaration(symbol:)`

Renders a full symbol declaration as syntax-highlighted HTML. Handles short/long formatting, attribute placement, and context-aware identifier highlighting based on the symbol kind.

### `Sigil.renderFragment(_:identifierClass:)`

Renders a single declaration fragment as a syntax-highlighted `<span>`. The optional `identifierClass` parameter controls how `.identifier` fragments are rendered (defaults to `.functionDefinition`).

### `Sigil.escapeHTML(_:)`

Escapes `&`, `<`, `>`, and `"` for safe HTML output.

## License

Sigil is available under the MIT license. See the LICENSE file for more info.
