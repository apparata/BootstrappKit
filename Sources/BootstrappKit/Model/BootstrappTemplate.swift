//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import Markin

public struct BootstrappTemplate: Hashable {
    
    public let id: String
    public let url: URL
    public let specification: BootstrappSpecification
    public let document: DocumentElement?
    public let previewImageFiles: [Path]
    public let presetsPath: Path?
    
    public var contentPath: Path {
        Path(url.appendingPathComponent("Content").path)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }
    
    public init(id: String,
                url: URL,
                specification: BootstrappSpecification,
                document: DocumentElement?,
                previewImageFiles: [Path],
                presetsPath: Path?) {
        self.id = id
        self.url = url
        self.specification = specification
        self.document = document
        self.previewImageFiles = previewImageFiles
        self.presetsPath = presetsPath
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
