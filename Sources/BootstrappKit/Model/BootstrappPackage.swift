//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import Foundation

public struct BootstrappPackage: Identifiable {
    public var id: String { name }
    public let name: String
    public let url: String
    public let version: String
    
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
