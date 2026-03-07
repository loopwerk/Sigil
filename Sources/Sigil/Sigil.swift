import SymbolKit

public enum Sigil {
  /// Escapes HTML special characters in a string.
  public static func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }

  /// Renders a single declaration fragment as a syntax-highlighted HTML span.
  ///
  /// Uses [Prism](https://prismjs.com)-compatible CSS class names:
  /// - `.keyword` for language keywords (`func`, `class`, `let`, etc.)
  /// - `.attribute.atrule` for attributes (`@discardableResult`, etc.)
  /// - `.class-name` for type identifiers and generic parameters
  /// - `.function-definition.function` for function/method identifiers
  /// - Plain text for everything else (punctuation, whitespace)
  ///
  /// The `identifierClass` parameter controls how `.identifier` fragments are rendered,
  /// since SymbolKit uses `.identifier` for all declared names regardless of symbol kind.
  public static func renderFragment(
    _ fragment: SymbolGraph.Symbol.DeclarationFragments.Fragment,
    identifierClass: IdentifierClass = .functionDefinition
  ) -> String {
    let text = escapeHTML(fragment.spelling)
    switch fragment.kind {
      case .keyword:
        return #"<span class="token keyword">\#(text)</span>"#
      case .attribute:
        return #"<span class="token attribute atrule">\#(text)</span>"#
      case .typeIdentifier, .genericParameter:
        return #"<span class="token class-name">\#(text)</span>"#
      case .identifier:
        switch identifierClass {
          case .functionDefinition:
            return #"<span class="token function-definition function">\#(text)</span>"#
          case .className:
            return #"<span class="token class-name">\#(text)</span>"#
          case .plain:
            return text
        }
      default:
        return text
    }
  }

  /// Controls how `.identifier` fragments are rendered in HTML.
  public enum IdentifierClass {
    /// Wrap in `<span class="token function-definition function">` — for functions, methods, initializers.
    case functionDefinition
    /// Wrap in `<span class="token class-name">` — for structs, enums, protocols, classes, typealiases, associated types.
    case className
    /// No wrapper — for properties, enum cases, variables.
    case plain
  }

  /// Returns the appropriate ``IdentifierClass`` for a symbol kind.
  public static func identifierClass(for symbolKind: SymbolGraph.Symbol.KindIdentifier) -> IdentifierClass {
    switch symbolKind {
      case .struct, .enum, .class, .protocol, .typealias, .associatedtype:
        return .className
      case .func, .method, .typeMethod, .`init`, .operator, .subscript, .typeSubscript, .macro, .deinit:
        return .functionDefinition
      default:
        return .plain
    }
  }

  /// Renders a symbol's declaration as syntax-highlighted HTML.
  ///
  /// For short declarations (<=80 characters), returns a single-line rendering.
  /// For long declarations with parameters, formats with one parameter per line (2-space indent).
  /// Declaration-level attributes (like `@discardableResult`) are always placed on their own line.
  ///
  /// Uses ``renderFragment(_:)`` for syntax highlighting individual tokens.
  public static func renderDeclaration(symbol: SymbolGraph.Symbol) -> String {
    guard let fragments = symbol.declarationFragments else {
      return escapeHTML(symbol.names.title)
    }

    let idClass = identifierClass(for: symbol.kind.identifier)

    // Separate declaration-level attributes (like @discardableResult) from the rest.
    var attrPrefix = ""
    var bodyFragments = fragments[...]
    while let first = bodyFragments.first,
          first.kind == .attribute || (first.kind == .text && first.spelling.trimmingCharacters(in: .whitespaces).isEmpty && attrPrefix.hasSuffix("\n"))
    {
      if first.kind == .attribute {
        attrPrefix += renderFragment(first) + "\n"
      }
      bodyFragments = bodyFragments.dropFirst()
    }

    let bodyPlainText = bodyFragments.map(\.spelling).joined()
    let bodyInline = bodyFragments.map { renderFragment($0, identifierClass: idClass) }.joined()

    // If the body (without attributes) fits on one line, just add attribute prefix
    guard bodyPlainText.count > 80 else { return attrPrefix + bodyInline }

    // Only format multi-line if there are actual parameters
    let hasParams = bodyFragments.contains {
      $0.kind == .externalParameter || $0.kind == .internalParameter
    }
    guard hasParams else { return attrPrefix + bodyInline }

    // Build formatted declaration with one parameter per line.
    let indent = "  "
    var result = attrPrefix
    var parenDepth = 0
    var angleDepth = 0
    var paramDepth = -1
    var paramListClosed = false

    for fragment in bodyFragments {
      guard fragment.kind == .text else {
        result += renderFragment(fragment, identifierClass: idClass)
        continue
      }

      let spelling = fragment.spelling
      var i = spelling.startIndex
      while i < spelling.endIndex {
        let char = spelling[i]

        if char == "<" {
          angleDepth += 1
          result += escapeHTML(String(char))
        } else if char == ">" {
          angleDepth = max(0, angleDepth - 1)
          result += escapeHTML(String(char))
        } else if char == "(" {
          parenDepth += 1
          if paramDepth == -1 { paramDepth = parenDepth }
          result += "("
          if parenDepth == paramDepth && !paramListClosed {
            result += "\n" + indent
          }
        } else if char == ")" && parenDepth == paramDepth && !paramListClosed {
          result += "\n)"
          parenDepth -= 1
          paramListClosed = true
        } else if char == ")" {
          parenDepth -= 1
          result += ")"
        } else if char == "," && parenDepth == paramDepth && angleDepth == 0 && !paramListClosed {
          let next = spelling.index(after: i)
          if next < spelling.endIndex && spelling[next] == " " {
            result += ",\n" + indent
            i = spelling.index(after: next)
            continue
          }
          result += ","
        } else {
          result += escapeHTML(String(char))
        }

        i = spelling.index(after: i)
      }
    }

    return result
  }
}
