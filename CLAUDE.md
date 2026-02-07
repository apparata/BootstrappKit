# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
swift build          # Build the package
swift test           # Run all tests
swift package clean  # Clean build artifacts
```

## Project Overview

BootstrappKit is a Swift framework (macOS 13+, Swift 5.9+) for project template instantiation. It takes template bundles containing a specification, content files, and optional documentation, then generates fully rendered projects with parameter substitution, conditional file/directory inclusion, and optional Xcode project generation via XcodeGen.

## Architecture

### Template Processing Pipeline

The core flow in `Bootstrapp.instantiateTemplate()`:

1. **Build context** — Merges date/time variables, specification substitutions, user-provided parameters, and Swift package dependencies into a `[String: Any?]` dictionary
2. **Prepare output** — Creates output directory at `/tmp/Results/YYYY-MM-DD/{rendered name}/`
3. **Build blacklists** — Evaluates conditional expressions (via TemplateKit's condition lexer/parser) to determine which directories and files to exclude
4. **Instantiate directories** — Renders directory names through TemplateKit, creates them in output
5. **Instantiate files** — Renders filenames; for files matching `parametrizableFiles` regex patterns, also renders content through TemplateKit; others are copied verbatim
6. **Project generation** — For `.xcodeProject` type, delegates to `XcodeProjectGenerator` which uses XcodeGen to produce an `.xcodeproj` from a YAML spec

### Key Types

- **`Bootstrapp`** (`Bootstrapp.swift`) — Orchestrator class that drives the entire instantiation pipeline
- **`BootstrappTemplate`** (`Model/BootstrappTemplate.swift`) — Loaded template bundle: specification, content path, documentation (Markin), preview images, presets
- **`BootstrappSpecification`** (`Model/BootstrappSpecification.swift`) — JSON-decoded template config defining project type (`.general`, `.swiftPackage`, `.xcodeProject`, meta-templates), parameters, substitutions, file inclusion rules, and parametrizable file patterns
- **`BootstrappParameter`** (`Model/BootstrappParameter.swift`) — Template parameter with types: `.string` (with optional regex validation), `.bool`, `.option`; supports conditional dependencies via `dependsOn`
- **`BootstrappPackage`** (`Model/BootstrappPackage.swift`) — Swift package dependency (name, URL, version) to include in generated projects
- **`XcodeProjectGenerator`** (`XcodeProjectGenerator.swift`) — Wraps XcodeGen to generate Xcode projects from YAML specifications

### Utilities

- **`Path`** — Custom file path abstraction over Foundation; supports path manipulation, file system queries, directory operations, and special directory accessors (home, temp, etc.)
- **`Regex`** — Convenience wrapper around `NSRegularExpression` with string-literal initialization and pattern matching
- **`VersionNumber`** — Semantic version parsing and comparison

### TemplateKit Syntax (../TemplateKit/)

BootstrappKit renders all template content through TemplateKit. The default tag delimiters are `<{` and `}>` (not Mustache `{{ }}`). Note: the doc comment examples in `BootstrappSpecification.swift` use `{{ }}` but this is outdated — actual templates use `<{ }>`.

**Variable substitution:**
```
<{ VARIABLE_NAME }>
<{ parent.child.property }>          (dot notation for nested access)
<{ #lowercased VARIABLE_NAME }>      (transformer)
<{ #uppercased #trimmed NAME }>      (chained transformers)
```

**Built-in transformers:** `#lowercased`, `#uppercased`, `#uppercasingFirstLetter`, `#lowercasingFirstLetter`, `#trimmed`, `#removingWhitespace`, `#collapsingWhitespace`

**Conditionals:**
```
<{ if BOOL_VAR }>...<{ end }>
<{ if not BOOL_VAR }>...<{ end }>
<{ if LICENSE_TYPE == 'MIT' }>...<{ else }>...<{ end }>
<{ if A and B }>    <{ if A or B }>    <{ if not (A and B) }>
```
Operators: `and`, `or`, `not`, `==`, `!=`, parentheses. Boolean evaluation: truthy if value exists and is non-nil (booleans evaluated directly).

**Loops:**
```
<{ for item in items }>
  <{ item.name }>
<{ end }>
```

**Imports:**
```
<{ import "path/to/file.txt" }>
```
Resolved relative to the `root` URL passed to `Template.render(context:root:)`.

**Condition expressions in specification JSON** (for `includeDirectories`/`includeFiles`) use the same expression grammar but are evaluated via `ConditionLexer`/`ConditionParser`/`ConditionalExpression` — the string is the condition itself, not wrapped in tags.

### Dependencies

- **XcodeGen** (branch: `synced_folder`) — Xcode project generation; currently pinned to a branch for Xcode 16 folder support (needs updating to a release version)
- **TemplateKit** (0.6.0) — Template rendering with condition evaluation
- **Markin** (0.7.1) — Markdown parsing for template documentation

### Conventions

- Models are immutable structs with `withValue()` copy methods for modification
- Files named `.ignored-placeholder` are automatically excluded (allows keeping empty directories in templates)
- Internal `Context` typealias is `[String: Any?]`
