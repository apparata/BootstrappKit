//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import Foundation

/// A Swift package dependency to include in a generated project.
public struct BootstrappPackage: Identifiable {

    /// The package name, also used as the unique identifier.
    public var id: String { name }

    /// The display name of the package (e.g. `"Alamofire"`).
    public let name: String

    /// The repository URL of the package.
    public let url: String

    /// The minimum version requirement (e.g. `"5.6.0"`).
    public let version: String

    /// Creates a new package dependency.
    ///
    /// - Parameters:
    ///   - name: The package name.
    ///   - url: The repository URL.
    ///   - version: The minimum version.
    public init(name: String, url: String, version: String) {
        self.name = name
        self.url = url
        self.version = version
    }
}

extension BootstrappPackage: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case version
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        version = try container.decode(String.self, forKey: .version)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(version, forKey: .version)
    }
}
