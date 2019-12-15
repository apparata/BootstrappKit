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

public struct BootstrappSpecification {

    public enum Error: Swift.Error {
        case unsupportedProjectType(String)
        case xcodeProjectRequiresProjectSpecification
    }
    
    public enum ProjectType {
        case xcodeMetaTemplate
        case swiftMetaTemplate
        case xcodeProject(specification: String)
        case swiftPackage
    }
    
    public struct IncludeDirectories {
        public let condition: String
        public let directories: [String]
    }

    public struct IncludeFiles {
        public let condition: String
        public let files: [String]
    }
    
    public let id: String
    public let specificationVersion: VersionNumber
    public let templateVersion: VersionNumber
    public let type: ProjectType
    public let description: String
    public let outputDirectoryName: String
    public let substitutions: [String: String]
    public let parameters: [BootstrappParameter]
    public let parametrizableFiles: [Regex]
    public let includeDirectories: [IncludeDirectories]
    public let includeFiles: [IncludeFiles]
}

extension BootstrappSpecification.ProjectType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .xcodeMetaTemplate: hasher.combine("xcodeMetaTemplate")
        case .swiftMetaTemplate: hasher.combine("swiftMetaTemplate")
        case .xcodeProject(let specification):
            hasher.combine("xcodeProject")
            hasher.combine(specification)
        case .swiftPackage: hasher.combine("swiftPackage")
        }
    }
}

extension BootstrappSpecification.ProjectType: Comparable {

    public var category: String {
        switch self {
        case .swiftMetaTemplate: return "Meta Templates"
        case .xcodeMetaTemplate: return "Meta Templates"
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
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Swift Package":
            self.type = .swiftPackage
        case "Xcode Project":
            guard let projectSpecification = try container.decodeIfPresent(String.self, forKey: .projectSpecification) else {
                throw Error.xcodeProjectRequiresProjectSpecification
            }
            self.type = .xcodeProject(specification: projectSpecification)
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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch type {
        case .xcodeProject(let specification):
            try container.encode("Xcode Project", forKey: .type)
            try container.encode(specification, forKey: .projectSpecification)
        case .swiftPackage:
            try container.encode("Swift Package", forKey: .type)
        case .xcodeMetaTemplate:
            try container.encode("Xcode Meta Template", forKey: .type)
        case .swiftMetaTemplate:
            try container.encode("Swift Meta Template", forKey: .type)
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
