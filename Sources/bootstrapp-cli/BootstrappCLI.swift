import ArgumentParser
import BootstrappKit
import Foundation

/// Command-line interface for instantiating projects from Bootstrapp template bundles.
///
/// Usage:
/// ```
/// bootstrapp-cli <template-path> --param KEY=VALUE --verbose
/// ```
@main
struct BootstrappCLI: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "bootstrapp-cli",
        abstract: "Instantiate a project from a Bootstrapp template bundle."
    )

    /// Path to the template bundle directory containing `Bootstrapp.json`.
    @Argument(help: "Path to the template bundle directory.")
    var templatePath: String

    /// Parameter overrides in `KEY=VALUE` format. Can be repeated.
    @Option(name: .long, parsing: .upToNextOption, help: "Parameter value in KEY=VALUE format. Repeatable.")
    var param: [String] = []

    /// Additional Swift package dependencies in `NAME,URL,VERSION` format. Can be repeated.
    @Option(name: .long, parsing: .upToNextOption, help: "Swift package in NAME,URL,VERSION format. Repeatable.")
    var package: [String] = []

    /// Names of spec-defined packages to exclude. Can be repeated.
    @Option(name: .long, parsing: .upToNextOption, help: "Exclude a spec-defined package by name. Repeatable.")
    var excludePackage: [String] = []

    /// An optional override for the output directory path.
    @Option(name: .long, help: "Override the output directory.")
    var outputDir: String?

    /// When set, prints detailed progress information during instantiation.
    @Flag(name: .long, help: "Print progress information.")
    var verbose: Bool = false

    /// Loads the template, applies parameter and package overrides, and runs
    /// the instantiation pipeline. Prints the output path on success.
    func run() throws {
        let bundleURL = URL(fileURLWithPath: (templatePath as NSString).expandingTildeInPath)
            .standardizedFileURL

        // Load specification
        let specURL = bundleURL.appendingPathComponent("Bootstrapp.json")
        guard FileManager.default.fileExists(atPath: specURL.path) else {
            throw ValidationError("Bootstrapp.json not found in \(bundleURL.path)")
        }

        if verbose {
            print("Loading specification from \(specURL.path)")
        }

        let specData = try Data(contentsOf: specURL)
        let specification = try JSONDecoder().decode(BootstrappSpecification.self, from: specData)

        // Check for Presets directory
        let presetsURL = bundleURL.appendingPathComponent("Presets")
        let presetsPath: Path?
        if FileManager.default.fileExists(atPath: presetsURL.path) {
            presetsPath = Path(presetsURL.path)
        } else {
            presetsPath = nil
        }

        // Build template
        let template = BootstrappTemplate(
            id: specification.id,
            url: bundleURL,
            specification: specification,
            document: nil,
            previewImageFiles: [],
            presetsPath: presetsPath
        )

        if verbose {
            print("Template: \(specification.id)")
            print("Type: \(specification.type)")
            print("Parameters: \(specification.parameters.map(\.id).joined(separator: ", "))")
        }

        // Apply parameter overrides
        var parameters = specification.parameters
        for paramString in param {
            guard let equalsIndex = paramString.firstIndex(of: "=") else {
                throw ValidationError("Invalid parameter format '\(paramString)'. Expected KEY=VALUE.")
            }
            let key = String(paramString[paramString.startIndex..<equalsIndex])
            let value = String(paramString[paramString.index(after: equalsIndex)...])

            guard let index = parameters.firstIndex(where: { $0.id == key }) else {
                throw ValidationError("Unknown parameter '\(key)'. Available: \(parameters.map(\.id).joined(separator: ", "))")
            }

            let parameter = parameters[index]
            switch parameter.type {
            case .string:
                parameters[index] = parameter.withValue(value: value)
            case .bool:
                parameters[index] = parameter.withValue(value: value.lowercased() == "true")
            case .option:
                if let intValue = Int(value) {
                    parameters[index] = parameter.withValue(value: intValue)
                } else if let optionIndex = parameter.options.firstIndex(of: value) {
                    parameters[index] = parameter.withValue(value: optionIndex)
                } else {
                    throw ValidationError(
                        "Invalid option value '\(value)' for parameter '\(key)'. "
                        + "Available options: \(parameter.options.joined(separator: ", "))"
                    )
                }
            }

            if verbose {
                print("  \(key) = \(value)")
            }
        }

        // Build packages: start with spec-defined packages, exclude any requested, then append CLI extras
        var packages = specification.packages
        if !excludePackage.isEmpty {
            if verbose {
                print("Excluding packages: \(excludePackage.joined(separator: ", "))")
            }
            packages.removeAll { excludePackage.contains($0.name) }
        }
        for packageString in package {
            let parts = packageString.split(separator: ",", maxSplits: 2).map(String.init)
            guard parts.count == 3 else {
                throw ValidationError("Invalid package format '\(packageString)'. Expected NAME,URL,VERSION.")
            }
            packages.append(BootstrappPackage(name: parts[0], url: parts[1], version: parts[2]))
        }

        if verbose {
            if packages.isEmpty {
                print("Packages: (none)")
            } else {
                print("Packages:")
                for pkg in packages {
                    print("  - \(pkg.name) \(pkg.url) \(pkg.version)")
                }
            }
        }

        // Run the pipeline
        if verbose {
            print("Instantiating template...")
        }

        let bootstrapp = Bootstrapp(template: template, parameters: parameters, packages: packages)
        let outputPath = try bootstrapp.instantiateTemplate()

        if verbose {
            print("Output: \(outputPath.string)")
        }

        print(outputPath.string)
    }
}
