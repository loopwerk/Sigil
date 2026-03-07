import SymbolKit

/// A mapping from declaration fragment kinds to CSS class names.
///
/// Use `nil` for any property to render that token as plain text without a wrapper `<span>`.
public struct CSSMapping {
  public var keyword: String?
  public var attribute: String?
  public var typeName: String?
  public var functionDefinition: String?
  public var typeDefinition: String?
  public var propertyDefinition: String?

  public init(
    keyword: String? = nil,
    attribute: String? = nil,
    typeName: String? = nil,
    functionDefinition: String? = nil,
    typeDefinition: String? = nil,
    propertyDefinition: String? = nil
  ) {
    self.keyword = keyword
    self.attribute = attribute
    self.typeName = typeName
    self.functionDefinition = functionDefinition
    self.typeDefinition = typeDefinition
    self.propertyDefinition = propertyDefinition
  }

  /// [Prism](https://prismjs.com)-compatible CSS classes.
  public static let prism = CSSMapping(
    keyword: "token keyword",
    attribute: "token attribute atrule",
    typeName: "token class-name",
    functionDefinition: "token function-definition function",
    typeDefinition: "token class-name"
  )

  /// [highlight.js](https://highlightjs.org)-compatible CSS classes.
  public static let highlightJS = CSSMapping(
    keyword: "hljs-keyword",
    attribute: "hljs-meta",
    typeName: "hljs-type",
    functionDefinition: "hljs-title function_",
    typeDefinition: "hljs-title class_"
  )
}

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
  /// The `identifierClass` parameter controls how `.identifier` fragments are rendered,
  /// since SymbolKit uses `.identifier` for all declared names regardless of symbol kind.
  public static func renderFragment(
    _ fragment: SymbolGraph.Symbol.DeclarationFragments.Fragment,
    identifierClass: IdentifierClass = .functionDefinition,
    cssMapping: CSSMapping? = .prism
  ) -> String {
    let text = escapeHTML(fragment.spelling)
    guard let cssMapping else { return text }
    switch fragment.kind {
      case .keyword:
        return wrap(text, cssClass: cssMapping.keyword)
      case .attribute:
        return wrap(text, cssClass: cssMapping.attribute)
      case .typeIdentifier, .genericParameter:
        return wrap(text, cssClass: cssMapping.typeName)
      case .identifier:
        switch identifierClass {
          case .functionDefinition:
            return wrap(text, cssClass: cssMapping.functionDefinition)
          case .typeDefinition:
            return wrap(text, cssClass: cssMapping.typeDefinition)
          case .plain:
            return wrap(text, cssClass: cssMapping.propertyDefinition)
        }
      default:
        return text
    }
  }

  /// Controls how `.identifier` fragments are rendered in HTML.
  public enum IdentifierClass {
    /// For functions, methods, initializers.
    case functionDefinition
    /// For structs, enums, protocols, classes, typealiases, associated types.
    case typeDefinition
    /// For properties, enum cases, variables.
    case plain
  }

  /// Returns the appropriate ``IdentifierClass`` for a symbol kind.
  public static func identifierClass(for symbolKind: SymbolGraph.Symbol.KindIdentifier) -> IdentifierClass {
    switch symbolKind {
      case .struct, .enum, .class, .protocol, .typealias, .associatedtype:
        return .typeDefinition
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
  public static func renderDeclaration(symbol: SymbolGraph.Symbol, cssMapping: CSSMapping? = .prism) -> String {
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
        attrPrefix += renderFragment(first, cssMapping: cssMapping) + "\n"
      }
      bodyFragments = bodyFragments.dropFirst()
    }

    let bodyPlainText = bodyFragments.map(\.spelling).joined()
    let bodyInline = bodyFragments.map { renderFragment($0, identifierClass: idClass, cssMapping: cssMapping) }.joined()

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
        result += renderFragment(fragment, identifierClass: idClass, cssMapping: cssMapping)
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

  private static func wrap(_ text: String, cssClass: String?) -> String {
    guard let cssClass else { return text }
    return #"<span class="\#(cssClass)">\#(text)</span>"#
  }
}
