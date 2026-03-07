# Sigil

Render Swift [SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit) declarations as syntax-highlighted HTML.

Takes the declaration fragments from a symbol graph (as produced by the SwiftPM command `swift package dump-symbol-graph`) and turns them into HTML with [Prism](https://prismjs.com)-compatible CSS classes, with smart multi-line formatting for long function signatures.

## Installation

Add Sigil as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/loopwerk/Sigil", branch: "main"),
```

(Since SymbolKit doesn't have normal releases, sadly Sigil has to depend on their main branch, which then infects the whole dependency tree.)

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

Sigil defaults to [Prism](https://prismjs.com)-compatible CSS classes but also ships with a [highlight.js](https://highlightjs.org) mapping. You can pass a different mapping to both `renderDeclaration` and `renderFragment`:

```swift
let html = Sigil.renderDeclaration(symbol: symbol, cssMapping: .highlightJS)
```

Pass `nil` to skip CSS classes entirely and get plain HTML-escaped text — useful when a client-side syntax highlighter handles tokenization:

```swift
let html = Sigil.renderDeclaration(symbol: symbol, cssMapping: nil)
```

## API

### `Sigil.renderDeclaration(symbol:cssMapping:)`

Renders a full symbol declaration as syntax-highlighted HTML. Handles short/long formatting, attribute placement, and context-aware identifier highlighting based on the symbol kind.

### `Sigil.renderFragment(_:identifierClass:cssMapping:)`

Renders a single declaration fragment as a syntax-highlighted `<span>`. The optional `identifierClass` parameter controls how `.identifier` fragments are rendered (defaults to `.functionDefinition`).

### `Sigil.escapeHTML(_:)`

Escapes `&`, `<`, `>`, and `"` for safe HTML output.

## License

Sigil is available under the MIT license. See the LICENSE file for more info.
