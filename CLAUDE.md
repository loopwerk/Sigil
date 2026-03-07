# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sigil is a Swift library that renders SymbolKit declaration fragments (from `swift package dump-symbol-graph`) into syntax-highlighted HTML with [Prism](https://prismjs.com)-compatible CSS classes. It handles smart multi-line formatting for long function signatures (>80 chars with parameters).

## Build & Test Commands

```bash
swift build          # Build the library
swift test           # Run all tests
swift test --filter SigilTests/testEscapeHTML   # Run a single test
```

## Architecture

Single-file library (`Sources/Sigil/Sigil.swift`) exposing an enum `Sigil` with three static methods:

- `escapeHTML(_:)` — HTML entity escaping
- `renderFragment(_:)` — maps a single `SymbolGraph.Symbol.DeclarationFragments.Fragment` to an HTML `<span>` with Prism CSS classes
- `renderDeclaration(symbol:)` — renders a full symbol declaration; handles attribute extraction (e.g. `@discardableResult` on its own line), short vs long formatting (<=80 chars inline, otherwise one parameter per line with 2-space indent), and nested paren/angle-bracket depth tracking

Tests use a real symbol graph fixture (`Tests/SigilTests/Fixtures/Saga.symbols.json`) loaded via `Bundle.module`. The fixture is from the [Saga](https://github.com/loopwerk/Saga) project.

## Dependencies

- [swift-docc-symbolkit](https://github.com/swiftlang/swift-docc-symbolkit) (branch: main) — provides `SymbolGraph` types
