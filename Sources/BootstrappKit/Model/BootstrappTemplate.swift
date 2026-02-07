//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation
import Markin

/// A loaded template bundle containing a specification, content files, optional
/// documentation, preview images, and XcodeGen presets.
///
/// Template bundles are directories on disk with a `Bootstrapp.json` specification
/// file, a `Content/` subdirectory holding the template files, and optional
/// `Documentation/`, `Preview/`, and `Presets/` directories.
public struct BootstrappTemplate: Hashable {

    /// A unique identifier for this template, typically matching the specification's `id`.
    public let id: String

    /// The file URL of the template bundle directory on disk.
    public let url: URL

    /// The decoded template specification (`Bootstrapp.json`).
    public let specification: BootstrappSpecification

    /// The parsed Markin documentation for this template, if available.
    public let document: DocumentElement?

    /// Paths to preview image files included in the template bundle.
    public let previewImageFiles: [Path]

    /// Path to the `Presets/` directory used by XcodeGen, if present.
    public let presetsPath: Path?

    /// The path to the `Content/` subdirectory that holds the template files.
    public var contentPath: Path {
        Path(url.appendingPathComponent("Content").path)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }

    /// Creates a new template from its constituent parts.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the template.
    ///   - url: The file URL of the template bundle directory.
    ///   - specification: The decoded template specification.
    ///   - document: Parsed Markin documentation, or `nil`.
    ///   - previewImageFiles: Paths to preview images.
    ///   - presetsPath: Path to the `Presets/` directory, or `nil`.
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
