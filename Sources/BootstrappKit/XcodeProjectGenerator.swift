//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import XcodeGenKit
import ProjectSpec
import XcodeProj
import PathKit
import Version

/// Generates an Xcode project (`.xcodeproj`) from a XcodeGen YAML specification.
///
/// Uses XcodeGen's `SpecLoader`, `ProjectGenerator`, and `FileWriter` to load,
/// validate, generate, and write the project to disk.
internal class XcodeProjectGenerator {

    /// Errors specific to Xcode project generation.
    enum Error: Swift.Error {
        /// The XcodeGen YAML specification file was not found at the expected path.
        case specificationFileDoesNotExist
    }

    init() {
        //
    }

    /// Generates an Xcode project from the given specification.
    ///
    /// - Parameters:
    ///   - specificationPath: Path to the XcodeGen YAML specification file.
    ///   - projectPath: The output directory for the generated project.
    ///   - context: The rendering context, used to populate the file header template.
    /// - Returns: The path to the generated `.xcodeproj` bundle.
    /// - Throws: ``Error/specificationFileDoesNotExist`` if the spec file is missing,
    ///   or any XcodeGen validation/generation error.
    func generate(specificationPath: Path, projectPath: Path, context: Context) throws -> Path {
        
        guard specificationPath.exists else {
            throw Error.specificationFileDoesNotExist
        }
        
        let projectSpecificationPath = PathKit.Path(specificationPath.string)
        let projectOutputPath = PathKit.Path(projectPath.string)

        let xcodeGenVersion = Version("2.25.0") // XcodeGen version.
        let specificationLoader = SpecLoader(version: xcodeGenVersion)
        
        let project = try specificationLoader.loadProject(path: projectSpecificationPath)
        print("Loaded project specification:\n  \(project.debugDescription.replacingOccurrences(of: "\n", with: "\n  "))")

        print("Validating project specification...")
        try project.validateMinimumXcodeGenVersion(xcodeGenVersion)
        try project.validate()
        
        print("Generating project...")
        let projectGenerator = ProjectGenerator(project: project)
        let username = NSUserName()
        let xcodeProject: XcodeProj = try projectGenerator.generateXcodeProject(userName: username)
        
        print("Writing project...")
        
        if !projectOutputPath.exists {
            try projectOutputPath.mkpath()
        }

        let xcodeProjectPath = projectOutputPath + (project.name + ".xcodeproj")
        let fileWriter = FileWriter(project: project)
        try fileWriter.writeXcodeProject(xcodeProject, to: xcodeProjectPath)
        try fileWriter.writePlists()
        
        try writeHeaderTemplate(under: xcodeProjectPath, context: context)
        
        print("Created project at \(projectPath)")
        
        return Path(xcodeProjectPath.string)
    }
    
    private func writeHeaderTemplate(under xcodeProjectPath: PathKit.Path, context: Context) throws {
        let templatePath = xcodeProjectPath + "xcshareddata/IDETemplateMacros.plist"
        let year: String = context["CURRENT_YEAR"] as? String ?? "YEAR"
        let copyrightHolder: String = context["COPYRIGHT_HOLDER"] as? String ?? "COPYRIGHT_HOLDER"
        let template = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>FILEHEADER</key>
            <string>
        //  Copyright © \(year) \(copyrightHolder). All rights reserved.
        //</string>
        </dict>
        </plist>
        """
        try template.write(to: templatePath.url, atomically: true, encoding: .utf8)
    }
}
