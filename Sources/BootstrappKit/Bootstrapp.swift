//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import TemplateKit

internal typealias Context = [String: Any?]

public class Bootstrapp {
    
    public let template: BootstrappTemplate
    public var specification: BootstrappSpecification { template.specification }
    public let parameters: [BootstrappParameter]
    private var blacklistedDirectories: [Path] = []
    private var blacklistedFiles: [Path] = []

    public init(template: BootstrappTemplate, parameters: [BootstrappParameter]) {
        self.template = template
        self.parameters = parameters
    }
    
    public func instantiateTemplate() throws -> Path {
        
        var context = makeDefaultContext()
        context = applySubstitutions(specification.substitutions, to: context)
        context = applyParameters(parameters, to: context)
        
        let outputPath = try prepareOutputDirectory(accordingTo: specification, with: context)
        let contentPath = template.contentPath
        let contentSubpaths = try contentPath.recursiveContentsOfDirectory(fullPaths: false)
        
        try buildDirectoryBlacklist(includeDirectories: specification.includeDirectories, with: context)
        try buildFileBlacklist(includeFiles: specification.includeFiles, with: context)

        try instantiateDirectories(atSubpaths: contentSubpaths,
                                   of: contentPath,
                                   to: outputPath,
                                   with: context)
        
        try instantiateFiles(atSubpaths: contentSubpaths,
                             of: contentPath,
                             to: outputPath,
                             with: context)
        
        switch specification.type {
        case .swiftPackage:
            return outputPath

        case .swiftMetaTemplate:
            return outputPath

        case .xcodeMetaTemplate:
            return outputPath
            
        case .xcodeProject(let specificationFilename):
            let projectSpecificationPath = outputPath.appendingComponent(specificationFilename)
            let projectGenerator = XcodeProjectGenerator()
            
            template.presetsPath?.becomeCurrentDirectory()
            
            let projectPath = try projectGenerator.generate(specificationPath: projectSpecificationPath,
                                                            projectPath: outputPath,
                                                            context: context)
            return projectPath
        }
        

    }
    
    // MARK: - Context
    
    private func makeDefaultContext() -> Context {
        var context: Context = [:]
        let now = Date()
        context["CURRENT_TIME"] = formatDate(now, options: .withTime)
        context["CURRENT_DATETIME"] = formatDate(now, options: .withInternetDateTime)
        context["CURRENT_DATE"] = formatDate(now, options: .withFullDate)
        context["CURRENT_YEAR"] = formatDate(now, options: .withYear)
        context["TEMPLATE_VERSION"] = template.specification.templateVersion.string
        return context
    }
    
    private func applySubstitutions(_ substitutions: [String: String],
                                    to inputContext: Context) -> Context {
        var context = inputContext
        for (id, substitution) in substitutions {
            context[id] = substitution
        }
        return context
    }
    
    private func applyParameters(_ parameters: [BootstrappParameter],
                                 to inputContext: Context) -> Context {
        var context = inputContext
        for parameter in parameters {
            if let value = parameter.anyValue {
                context[parameter.id] = value
            }
        }
        return context
    }
    
    // MARK: - Output Path
    
    private func prepareOutputDirectory(accordingTo specification: BootstrappSpecification,
                                      with context: Context) throws -> Path {
        let renderedDirectoryName = try Template(specification.outputDirectoryName).render(context: context)
        let outputPath = Path.temporaryDirectory.appendingComponent(renderedDirectoryName)
        
        if outputPath.exists {
            try outputPath.remove()
        }
        
        try outputPath.createDirectory(withIntermediateDirectories: true, attributes: nil)
        
        return outputPath
    }
    
    // MARK: - Directory Blacklisting
    
    private func buildDirectoryBlacklist(includeDirectories: [BootstrappSpecification.IncludeDirectories],
                                         with context: Context) throws {
        var blacklistedDirectories: [Path] = []
        for entry in includeDirectories {
            
            let conditionTokens = try ConditionLexer().tokenize(entry.condition)
            let condition = try ConditionParser().parse(conditionTokens)
            
            // Don't add entry to blacklist if inclusion condition is true.
            if condition.evaluate(with: context) {
                continue
            }
            
            let paths: [Path] = entry.directories.map { Path($0) }
            blacklistedDirectories.append(contentsOf: paths)
        }
        self.blacklistedDirectories = blacklistedDirectories
    }
    
    private func shouldIncludeDirectory(at path: Path) -> Bool {
        for blacklistedDirectory in blacklistedDirectories {
            // TODO: Using hasPrefix is not entirely correct. Improve it.
            if path.internalPath.hasPrefix(blacklistedDirectory.internalPath) {
                return false
            }
        }
        return true
    }

    // MARK: - File Blacklisting
    
    private func buildFileBlacklist(includeFiles: [BootstrappSpecification.IncludeFiles],
                                   with context: Context) throws {
        var blacklistedFiles: [Path] = []
        for entry in includeFiles {
            
            let conditionTokens = try ConditionLexer().tokenize(entry.condition)
            let condition = try ConditionParser().parse(conditionTokens)
            
            // Don't add entry to blacklist if inclusion condition is true.
            if condition.evaluate(with: context) {
                continue
            }
            
            let paths: [Path] = entry.files.map { Path($0) }
            blacklistedFiles.append(contentsOf: paths)
        }
        self.blacklistedFiles = blacklistedFiles
    }
    
    private func shouldIncludeFile(at path: Path) -> Bool {
        for blacklistedFile in blacklistedFiles {
            if path.internalPath == blacklistedFile.internalPath {
                return false
            }
        }
        return true
    }
    
    // MARK: - Directory & File Instantiation
    
    private func instantiateDirectories(atSubpaths contentSubpaths: [Path],
                                      of contentPath: Path,
                                      to outputPath: Path,
                                      with context: Context) throws {
        // Instantiate directories with rendered filenames.
        let directories = contentSubpaths.filter { (contentPath + $0).isDirectory }
        for directoryPath in directories {
            
            guard shouldIncludeDirectory(at: directoryPath) else {
                continue
            }
            
            let renderedDirectoryPath = Path(try Template(directoryPath.string).render(context: context))
            let destinationPath = outputPath + renderedDirectoryPath
            try destinationPath.createDirectory(withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func instantiateFiles(atSubpaths contentSubpaths: [Path],
                                 of contentPath: Path,
                                 to outputPath: Path,
                                 with context: Context) throws {
        // Instantiate files with rendered filenames and content.
        let files = contentSubpaths.filter { !(contentPath + $0).isDirectory }
        for filePath in files {
            
            guard shouldIncludeFile(at: filePath) else {
                continue
            }
            
            let renderedFilePath = Path(try Template(filePath.string).render(context: context))
            let sourcePath = contentPath + filePath
            let destinationPath = outputPath + renderedFilePath
            
            if shouldParametrizeFile(renderedFilePath, accordingTo: specification) {
                let string = try String(contentsOf: sourcePath.url, encoding: .utf8)
                let output = (try Template(string).render(context: context)).data(using: .utf8)
                try output?.write(to: destinationPath.url)
            } else {
                try sourcePath.copy(to: destinationPath)
            }
        }
    }
}

extension Bootstrapp {
    
    // MARK: - File Pattern Matcher
    
    private func shouldParametrizeFile(_ file: Path,
                                     accordingTo specification: BootstrappSpecification) -> Bool {
        for regex in specification.parametrizableFiles {
            if regex.isMatch(file.lastComponent) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Date Helpers

    private static let dateFormatter = ISO8601DateFormatter()
    private static let yearFormatter = DateFormatter()
    
    private func formatDate(_ date: Date, options: ISO8601DateFormatter.Options) -> String {
        // Kludge workaround, because the formatter is not returning the year.
        if options == .withYear {
            Self.yearFormatter.dateFormat = "yyyy"
            return Self.yearFormatter.string(from: date)
        } else {
            Self.dateFormatter.formatOptions = options
            return Self.dateFormatter.string(from: date)
        }
    }
}
