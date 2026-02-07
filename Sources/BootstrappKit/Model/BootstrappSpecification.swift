//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

/* --- Example ----------------------------------------------------------------

 Swift Package Example:
 
 {
     "specificationVersion": "1.0.0",
     "templateVersion": "1.0.0",
     "id": "Library Swift Package",
     "type": "Swift Package",
     "description": "Use this template to quickly set up new static library Swift packages, complete with e.g. MIT license file, SwiftLint configuration, Jazzy documentation build script.",
     "outputDirectoryName": "{{LIBRARY_NAME}}",
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
             "name": "Copyright Holder",
             "id": "COPYRIGHT_HOLDER",
             "type": "String",
             "default": "Apparata AB"
         },
         {
             "name": "License",
             "id": "LICENSE_TYPE",
             "type": "Option",
             "default": 0,
             "options": [
                 "MIT",
                 "BSD",
                 "Apache 2",
                 "Zlib"
             ]
         },
         {
             "name": "Add Executable Target",
             "id": "ADD_EXECUTABLE_TARGET",
             "type": "Bool",
             "default": false
         },
         {
             "name": "Executable Name",
             "id": "EXECUTABLE_NAME",
             "type": "String",
             "validationRegex": "^[A-Za-z0-9_]+$",
             "dependsOn": "ADD_EXECUTABLE_TARGET"
         }
     ],
     "parametrizableFiles": [
         "LICENSE",
         ".*\\.md",
         ".*\\.swift",
         ".*\\.h",
         ".*\\.m",
         ".*\\.mm",
         ".*\\.json",
         ".*\\.yml",
         ".*\\.txt",
         ".*\\.sh"
     ],
     "includeDirectories": [
         {
             "if": "ADD_EXECUTABLE_TARGET",
             "directories": [
                 "<{EXECUTABLE_NAME}>"
             ]
         }
     ],
     "includeFiles": [
         {
             "if": "LICENSE_TYPE == 'UNLICENSED'",
             "files": [
                 "UNLICENSED"
             ]
         }
     ]
 }

 Xcode Project Example:
 
 {
     "specificationVersion": "1.0.0",
     "templateVersion": "1.0.0",
     "id": "Shoebox Mac App",
     "type": "Xcode Project",
     "description": "Use this template to quickly set up a shoebox type macOS app Xcode project. A shoebox app is an app that typically only has one window and operates on a single database, as opposed to document-based apps.",
     "projectSpecification": "XcodeProject.yml",
     "outputDirectoryName": "{{APP_NAME}}",
     "substitutions": {
         "DOT": "."
     },
     "parameters": [
         {
             "name": "App Name",
             "id": "APP_NAME",
             "type": "String",
             "validationRegex": "^[A-Za-z0-9_\\- ]+$"
         },
         {
             "name": "Bundle ID Prefix",
             "id": "BUNDLE_ID_PREFIX",
             "type": "String",
             "validationRegex": "^[A-Za-z0-9_\\-\\.]+$",
             "default": "se.apparata"
         },
         {
             "name": "Copyright Holder",
             "id": "COPYRIGHT_HOLDER",
             "type": "String",
             "default": "Apparata AB"
         },
         {
             "name": "License",
             "id": "LICENSE_TYPE",
             "type": "Option",
             "default": 0,
             "options": [
                 "MIT",
                 "BSD",
                 "Apache 2",
                 "Zlib"
             ]
         },
     ],
     "parametrizableFiles": [
         "LICENSE",
         ".*\\.md",
         ".*\\.swift",
         ".*\\.h",
         ".*\\.m",
         ".*\\.mm",
         ".*\\.json",
         ".*\\.yml",
         ".*\\.txt",
         ".*\\.sh"
     ]
 }


---------------------------------------------------------------------------- */

/// The decoded representation of a `Bootstrapp.json` template specification.
///
/// A specification defines the project type, user-facing parameters, file
/// inclusion rules, parametrizable file patterns, substitutions, and optional
/// Swift package dependencies. It is the central configuration that drives
/// the template instantiation pipeline in ``Bootstrapp``.
public struct BootstrappSpecification {

    /// Errors that can occur when decoding a specification.
    public enum Error: Swift.Error {
        /// The `type` string in the JSON does not match any known project type.
        case unsupportedProjectType(String)
        /// An `"Xcode Project"` type requires a `projectSpecification` field.
        case xcodeProjectRequiresProjectSpecification
    }

    /// The kind of project a template produces.
    public enum ProjectType {
        /// A meta-template that generates general project templates.
        case generalMetaTemplate
        /// A meta-template that generates Xcode project templates.
        case xcodeMetaTemplate
        /// A meta-template that generates Swift package templates.
        case swiftMetaTemplate
        /// A general-purpose project (no Xcode project or Swift package generation).
        case general
        /// An Xcode project, with the associated XcodeGen YAML specification filename.
        case xcodeProject(specification: String)
        /// A Swift package project.
        case swiftPackage
    }

    /// A conditional rule for including or excluding directories during instantiation.
    public struct IncludeDirectories {
        /// A condition expression evaluated against the template context.
        public let condition: String
        /// Directory paths to include when the condition is true.
        public let directories: [String]
    }

    /// A conditional rule for including or excluding files during instantiation.
    public struct IncludeFiles {
        /// A condition expression evaluated against the template context.
        public let condition: String
        /// File paths to include when the condition is true.
        public let files: [String]
    }

    /// The unique identifier of the template (e.g. `"Library Swift Package"`).
    public let id: String

    /// The version of the specification format itself.
    public let specificationVersion: VersionNumber

    /// The version of this particular template.
    public let templateVersion: VersionNumber

    /// The kind of project this template produces.
    public let type: ProjectType

    /// A human-readable description of what the template does.
    public let description: String

    /// A TemplateKit expression for the output directory name (e.g. `"<{ APP_NAME }>"`).
    public let outputDirectoryName: String

    /// Static key-value pairs injected into the rendering context.
    public let substitutions: [String: String]

    /// The user-facing parameters defined by this template.
    public let parameters: [BootstrappParameter]

    /// Regex patterns that determine which files have their content rendered through TemplateKit.
    public let parametrizableFiles: [Regex]

    /// Conditional directory inclusion rules.
    public let includeDirectories: [IncludeDirectories]

    /// Conditional file inclusion rules.
    public let includeFiles: [IncludeFiles]

    /// Swift package dependencies defined by the template.
    public let packages: [BootstrappPackage]
}

extension BootstrappSpecification.ProjectType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .generalMetaTemplate: hasher.combine("generalMetaTemplate")
        case .xcodeMetaTemplate: hasher.combine("xcodeMetaTemplate")
        case .swiftMetaTemplate: hasher.combine("swiftMetaTemplate")
        case .general: hasher.combine("general")
        case .xcodeProject(let specification):
            hasher.combine("xcodeProject")
            hasher.combine(specification)
        case .swiftPackage: hasher.combine("swiftPackage")
        }
    }
}

extension BootstrappSpecification.ProjectType: Comparable {

    /// A display category used for grouping templates in the UI.
    public var category: String {
        switch self {
        case .generalMetaTemplate: return "Meta Templates"
        case .swiftMetaTemplate: return "Meta Templates"
        case .xcodeMetaTemplate: return "Meta Templates"
        case .general: return "General"
        case .swiftPackage: return "Swift Packages"
        case .xcodeProject(_): return "Xcode Projects"
        }
    }

    public static func < (lhs: BootstrappSpecification.ProjectType, rhs: BootstrappSpecification.ProjectType) -> Bool {
        return lhs.category < rhs.category
    }
}

// ---------------------------------------------------------------------------
// MARK: - Codable
// ---------------------------------------------------------------------------
        
extension BootstrappSpecification: Codable {
        
    enum CodingKeys: String, CodingKey {
        case id
        case version = "specificationVersion"
        case type
        case description
        case projectSpecification
        case outputDirectoryName
        case substitutions
        case parameters
        case parametrizableFiles
        case includeDirectories
        case includeFiles
        case packages
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "General":
            self.type = .general
        case "Swift Package":
            self.type = .swiftPackage
        case "Xcode Project":
            guard let projectSpecification = try container.decodeIfPresent(String.self, forKey: .projectSpecification) else {
                throw Error.xcodeProjectRequiresProjectSpecification
            }
            self.type = .xcodeProject(specification: projectSpecification)
        case "General Meta Template":
            self.type = .generalMetaTemplate
        case "Swift Meta Template":
            self.type = .swiftMetaTemplate
        case "Xcode Meta Template":
            self.type = .xcodeMetaTemplate
        default:
            throw Error.unsupportedProjectType(type)
        }

        
        id = try container.decode(String.self, forKey: .id)
        let specificationVersionString = try container.decode(String.self, forKey: .version)
        specificationVersion = try VersionNumber(specificationVersionString)
        let templateVersionString = try container.decode(String.self, forKey: .version)
        templateVersion = try VersionNumber(templateVersionString)
        description = try container.decode(String.self, forKey: .description)
        outputDirectoryName = try container.decode(String.self, forKey: .outputDirectoryName)
        substitutions = try container.decodeIfPresent([String: String].self, forKey: .substitutions) ?? [:]
        parameters = try container.decodeIfPresent([BootstrappParameter].self, forKey: .parameters) ?? []
        let patterns = try container.decodeIfPresent([String].self, forKey: .parametrizableFiles) ?? []
        parametrizableFiles = patterns.map { Regex("^\($0)$") }
        includeDirectories = try container.decodeIfPresent([IncludeDirectories].self, forKey: .includeDirectories) ?? []
        includeFiles = try container.decodeIfPresent([IncludeFiles].self, forKey: .includeFiles) ?? []
        packages = try container.decodeIfPresent([BootstrappPackage].self, forKey: .packages) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch type {
        case .generalMetaTemplate:
            try container.encode("General Meta Template", forKey: .type)
        case .swiftMetaTemplate:
            try container.encode("Swift Meta Template", forKey: .type)
        case .xcodeMetaTemplate:
            try container.encode("Xcode Meta Template", forKey: .type)
        case .general:
            try container.encode("General", forKey: .type)
        case .swiftPackage:
            try container.encode("Swift Package", forKey: .type)
        case .xcodeProject(let specification):
            try container.encode("Xcode Project", forKey: .type)
            try container.encode(specification, forKey: .projectSpecification)
        }
        
        try container.encode(id, forKey: .id)
        try container.encode(specificationVersion.string, forKey: .version)
        try container.encode(templateVersion.string, forKey: .version)
        try container.encode(description, forKey: .description)
        try container.encode(outputDirectoryName, forKey: .outputDirectoryName)
        try container.encode(substitutions, forKey: .substitutions)
        try container.encode(parameters, forKey: .parameters)
        let patterns: [String] = parametrizableFiles.map {
            String($0.pattern.dropFirst().dropLast())
        }
        try container.encode(patterns, forKey: .parametrizableFiles)
        try container.encode(includeDirectories, forKey: .includeDirectories)
        try container.encode(includeFiles, forKey: .includeFiles)
        try container.encode(packages, forKey: .packages)
    }
}

extension BootstrappSpecification.IncludeDirectories: Codable {
    
    enum CodingKeys: String, CodingKey {
        case condition = "if"
        case directories
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decode(String.self, forKey: .condition)
        directories = try container.decode([String].self, forKey: .directories)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(condition, forKey: .condition)
        try container.encode(directories, forKey: .directories)
    }
}

extension BootstrappSpecification.IncludeFiles: Codable {
    
    enum CodingKeys: String, CodingKey {
        case condition = "if"
        case files
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        condition = try container.decode(String.self, forKey: .condition)
        files = try container.decode([String].self, forKey: .files)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(condition, forKey: .condition)
        try container.encode(files, forKey: .files)
    }
}
