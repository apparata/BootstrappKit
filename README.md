# BootstrappKit

A Swift framework for project template instantiation. BootstrappKit takes template bundles containing a specification, content files, and optional documentation, then generates fully rendered projects with parameter substitution, conditional file/directory inclusion, and optional Xcode project generation via XcodeGen.

## Template Bundle Structure

A template bundle is a directory with the following layout:

```
MyTemplate/
    Bootstrapp.json          # Template specification (required)
    Content/                 # Template files and directories (required)
        <{ PROJECT_NAME }>/
            main.swift
            ...
    Documentation/           # Markin documentation (optional)
    Preview/                 # Preview images (optional)
    Presets/                 # XcodeGen presets (optional)
```

## Template Specification

The `Bootstrapp.json` file defines the template configuration:

```json
{
    "specificationVersion": "1.0.0",
    "templateVersion": "1.0.0",
    "id": "Library Swift Package",
    "type": "Swift Package",
    "description": "A library Swift package template.",
    "outputDirectoryName": "<{ LIBRARY_NAME }>",
    "substitutions": {
        "DOT": "."
    },
    "parameters": [
        {
            "name": "Library Name",
            "id": "LIBRARY_NAME",
            "type": "String",
            "validationRegex": "^[A-Za-z0-9_]+$"
        },
        {
            "name": "Include Tests",
            "id": "INCLUDE_TESTS",
            "type": "Bool",
            "default": true
        },
        {
            "name": "License",
            "id": "LICENSE_TYPE",
            "type": "Option",
            "default": 0,
            "options": ["MIT", "BSD", "Apache 2"]
        }
    ],
    "parametrizableFiles": [
        ".*\\.swift",
        ".*\\.md",
        ".*\\.json",
        ".*\\.yml"
    ],
    "includeDirectories": [
        {
            "if": "INCLUDE_TESTS",
            "directories": ["Tests"]
        }
    ],
    "includeFiles": [
        {
            "if": "LICENSE_TYPE == 'MIT'",
            "files": ["LICENSE-MIT"]
        }
    ]
}
```

### Project Types

| Type | JSON value | Description |
|------|-----------|-------------|
| General | `"General"` | Plain file generation, no project structure |
| Swift Package | `"Swift Package"` | Generates a Swift package |
| Xcode Project | `"Xcode Project"` | Generates an `.xcodeproj` via XcodeGen (requires `projectSpecification` field) |
| General Meta Template | `"General Meta Template"` | A template that produces other templates |
| Swift Meta Template | `"Swift Meta Template"` | A meta-template for Swift package templates |
| Xcode Meta Template | `"Xcode Meta Template"` | A meta-template for Xcode project templates |

### Parameter Types

- **String** -- Free-text value, optionally validated by `validationRegex`.
- **Bool** -- A boolean toggle.
- **Option** -- A selection from a list of string `options`, stored as an index.

Parameters can declare `dependsOn` to reference another parameter's `id`, making them conditionally relevant.

## TemplateKit Syntax

Template content is rendered through [TemplateKit](https://github.com/apparata/TemplateKit). The tag delimiters are `<{` and `}>`.

### Variable Substitution

```
<{ VARIABLE_NAME }>
<{ #lowercased VARIABLE_NAME }>
<{ #uppercased #trimmed VARIABLE_NAME }>
```

Built-in transformers: `#lowercased`, `#uppercased`, `#uppercasingFirstLetter`, `#lowercasingFirstLetter`, `#trimmed`, `#removingWhitespace`, `#collapsingWhitespace`.

### Conditionals

```
<{ if BOOL_VAR }>...<{ end }>
<{ if not BOOL_VAR }>...<{ end }>
<{ if LICENSE_TYPE == 'MIT' }>...<{ else }>...<{ end }>
<{ if A and B }>   <{ if A or B }>   <{ if not (A and B) }>
```

### Loops

```
<{ for item in items }>
    <{ item.name }>
<{ end }>
```

### Imports

```
<{ import "path/to/file.txt" }>
```

## Framework Usage

```swift
import BootstrappKit

// Load and decode the specification
let specData = try Data(contentsOf: specURL)
let specification = try JSONDecoder().decode(BootstrappSpecification.self, from: specData)

// Build the template
let template = BootstrappTemplate(
    id: specification.id,
    url: bundleURL,
    specification: specification,
    document: nil,
    previewImageFiles: [],
    presetsPath: nil
)

// Set parameter values
var parameters = specification.parameters
if let index = parameters.firstIndex(where: { $0.id == "LIBRARY_NAME" }) {
    parameters[index] = parameters[index].withValue(value: "MyLibrary")
}

// Instantiate
let bootstrapp = Bootstrapp(
    template: template,
    parameters: parameters,
    packages: []
)
let outputPath = try bootstrapp.instantiateTemplate()
print("Generated project at: \(outputPath)")
```

Output is written to `$TMPDIR/Results/YYYY-MM-DD/<rendered-name>/`.

## CLI Usage

The package includes a `bootstrapp-cli` executable:

```bash
# Build and run
swift run bootstrapp-cli /path/to/MyTemplate \
    --param LIBRARY_NAME=MyLibrary \
    --param INCLUDE_TESTS=true \
    --verbose

# Add extra Swift package dependencies
swift run bootstrapp-cli /path/to/MyTemplate \
    --param APP_NAME=MyApp \
    --package Alamofire,https://github.com/Alamofire/Alamofire.git,5.6.0

# Exclude a spec-defined package
swift run bootstrapp-cli /path/to/MyTemplate \
    --param APP_NAME=MyApp \
    --exclude-package SomePackage
```

The CLI prints the output path on the last line of stdout.

## Claude Code Skill

BootstrappKit includes a [Claude Code](https://claude.ai/code) skill that provides an interactive wrapper around `bootstrapp-cli`. Install it by placing the skill file at `~/.claude/skills/bootstrapp/SKILL.md`, then invoke it from Claude Code with:

```
/bootstrapp /path/to/MyTemplate
```

The skill reads the template's `Bootstrapp.json`, prompts you to confirm or change every parameter value, lets you select which packages to include, and then runs the CLI to generate the project.

## License

BootstrappKit is released under the MIT license. See [LICENSE](LICENSE) for details.
