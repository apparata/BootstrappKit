//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

/// Represents a file system path.
///
/// - Example:
/// ```
/// let absolutePath = Path("/usr/bin/zip")
/// absolutePath.isAbsolute
/// absolutePath.isRelative
///
/// let relativePath = Path("bin/whatever")
/// relativePath.isAbsolute
/// relativePath.isRelative
///
/// let concatenatedPath = Path("/usr") + Path("/bin")
///
/// let messyPath = Path("//usr/../usr/local/bin/./whatever")
/// messyPath.normalized
///
/// let pathFromLiteralString: Path = "/this/is/a/path"
/// let pathFromEmptyString: Path = ""
/// let pathFromConcatenatedStrings: Path = "/usr" + "/bin"
///
/// let pathFromComponents = Path(components: ["/", "usr/", "bin", "/", "swift"])
/// let pathFromEmptyComponents = Path(components: [])
///
/// let appendedPath = Path("/usr/local").appendingComponent("bin")
/// let appendedPath3 = Path("/usr/local").appending(Path("bin"))
/// let appendedPath2 = Path("/usr/local") + Path("bin")
///
/// let imagePath = Path("photos/photo").appendingExtension("jpg")
/// imagePath.extension
///
/// let imagePathWithoutExtension = imagePath.deletingExtension
/// let imagePathWithoutLastComponent = imagePath.deletingLastComponent
///
/// absolutePath.exists
/// absolutePath.isFile
/// absolutePath.isDirectory
/// absolutePath.isDeletable
/// absolutePath.isExecutable
/// absolutePath.isReadable
/// absolutePath.isWritable
/// ```
public struct Path {
    
    fileprivate var path: String
    
    var internalPath: String {
        path
    }
        
    /// Whether this is an absolute path (starts with `/`).
    public var isAbsolute: Bool {
        path.first == "/"
    }

    /// Whether this is a relative path.
    public var isRelative: Bool {
        !isAbsolute
    }

    /// A standardized version of the path with resolved `..` and `.` components.
    public var normalized: Path {
        Path((path as NSString).standardizingPath)
    }

    /// The underlying string representation of the path.
    public var string: String {
        path
    }

    /// A file URL representation of the path.
    public var url: URL {
        URL(fileURLWithPath: path)
    }

    /// Creates a path representing the current directory (`.`).
    public init() {
        path = "."
    }

    /// Creates a path from a string. An empty string is treated as `.`.
    public init(_ path: String) {
        if path.isEmpty {
            self.path = "."
        } else {
            self.path = path
        }
    }
    
    /// Returns a new path with the given path appended.
    public func appending(_ path: Path) -> Path {
        Path((self.path as NSString).appendingPathComponent(path.path))
    }

    /// Creates a path by joining a collection of string components.
    public init<T: Collection>(components: T) where T.Iterator.Element == String {
        if components.isEmpty {
            path = "."
        } else {
            let strings: [String] = components.map { $0 }
            path = NSString.path(withComponents: strings)
        }
    }
    
    /// The last path component (filename or directory name).
    public var lastComponent: String {
        (path as NSString).lastPathComponent
    }

    /// The path with its last component removed.
    public var deletingLastComponent: Path {
        Path((path as NSString).deletingLastPathComponent)
    }

    /// Returns a new path with the given string appended as a path component.
    public func appendingComponent(_ string: String) -> Path {
        Path((path as NSString).appendingPathComponent(string))
    }

    /// Returns a new path with the last component replaced by the given string.
    public func replacingLastComponent(with string: String) -> Path {
        deletingLastComponent.appendingComponent(string)
    }

    /// The file extension of the last path component, or an empty string if none.
    public var `extension`: String {
        (path as NSString).pathExtension
    }

    /// The path with the file extension removed from the last component.
    public var deletingExtension: Path {
        Path((path as NSString).deletingPathExtension)
    }

    /// Returns a new path with the given file extension appended.
    public func appendingExtension(_ string: String) -> Path {
        guard let newPath = (path as NSString).appendingPathExtension(string) else {
            // Not sure what could cause it to be nil, so here's a fallback plan.
            return Path(path + "." + string)
        }
        return Path(newPath)
    }
    
    /// Returns a new path with the file extension replaced by the given string.
    public func replacingExtension(with string: String) -> Path {
        deletingExtension.appendingExtension(string)
    }
}

// MARK: - Object Description

extension Path: CustomStringConvertible {
    public var description: String {
        path
    }
}

// MARK: - String Literal Convertible

extension Path: ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        path = "\(value)"
        if path.isEmpty {
            path = "."
        }
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        path = value
        if path.isEmpty {
            path = "."
        }
    }
    
    public init(stringLiteral value: StringLiteralType) {
        path = value
        if path.isEmpty {
            path = "."
        }
    }
}

// MARK: - Hashable, Equatable, Comparable

extension Path: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

extension Path: Equatable {
    
    public static func ==(lhs: Path, rhs: Path) -> Bool {
        lhs.path == rhs.path
    }
}

extension Path : Comparable {
 
    public static func <(lhs: Path, rhs: Path) -> Bool {
        lhs.path < rhs.path
    }
}

// MARK: - Concatenation

/// Concatenates two paths by appending `rhs` as a path component of `lhs`.
public func +(lhs: Path, rhs: Path) -> Path {
    lhs.appending(rhs)
}

/// Concatenates a path and a string by appending the string as a path component.
public func +(lhs: Path, rhs: String) -> Path {
    lhs.appendingComponent(rhs)
}

// MARK: - File Management

public extension Path {
    
    fileprivate static var fileManager: FileManager {
        FileManager.default
    }
    
    fileprivate var fileManager: FileManager {
        FileManager.default
    }
    
    /// Note: No-op if file does not exist.
    func excludeFromBackup() throws {
        guard exists else {
            return
        }
        
        let mutableURL: NSURL = url as NSURL
        
        try mutableURL.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
    }
    
    /// Whether a file or directory exists at this path.
    var exists: Bool {
        fileManager.fileExists(atPath: internalPath)
    }

    /// Whether no file or directory exists at this path.
    var doesNotExist: Bool {
        !exists
    }

    /// Whether the path points to a file (i.e. is not a directory).
    var isFile: Bool {
        !isDirectory
    }

    /// Whether the path points to a directory.
    var isDirectory: Bool {
        var isDirectory = ObjCBool(false)
        if fileManager.fileExists(atPath: internalPath, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }
        return false
    }
    
    /// Whether the file at this path can be deleted.
    var isDeletable: Bool {
        fileManager.isDeletableFile(atPath: internalPath)
    }

    /// Whether the file at this path is executable.
    var isExecutable: Bool {
        fileManager.isExecutableFile(atPath: internalPath)
    }

    /// Whether the file at this path is readable.
    var isReadable: Bool {
        fileManager.isReadableFile(atPath: internalPath)
    }

    /// Whether the file at this path is writable.
    var isWritable: Bool {
        fileManager.isWritableFile(atPath: internalPath)
    }

    /// Returns the immediate contents of the directory at this path.
    ///
    /// - Parameter fullPaths: If `true`, returned paths are absolute; otherwise relative names.
    func contentsOfDirectory(fullPaths: Bool = false) throws -> [Path] {
        let pathStrings = try fileManager.contentsOfDirectory(atPath: internalPath)
        let paths: [Path]
        if fullPaths {
            paths = pathStrings.map {
                self.appendingComponent($0)
            }
        } else {
            paths = pathStrings.map {
                Path($0)
            }
        }
        return paths
    }

    /// Returns all contents of the directory recursively.
    ///
    /// - Parameter fullPaths: If `true`, returned paths are absolute; otherwise relative subpaths.
    func recursiveContentsOfDirectory(fullPaths: Bool = false) throws -> [Path] {
        let pathStrings = try fileManager.subpathsOfDirectory(atPath: internalPath)
        let paths: [Path]
        if fullPaths {
            paths = pathStrings.map {
                self.appendingComponent($0)
            }
        } else {
            paths = pathStrings.map {
                Path($0)
            }
        }
        return paths
    }

    
    /// The current working directory.
    static var currentDirectory: Path {
        Path(fileManager.currentDirectoryPath)
    }

    /// The user's home directory.
    static var homeDirectory: Path {
        Path(NSHomeDirectory())
    }

    /// The system temporary directory.
    static var temporaryDirectory: Path {
        Path(NSTemporaryDirectory())
    }

    /// The user's Documents directory, or `nil` if unavailable.
    static var documentDirectory: Path? {
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last {
            return Path(documentDirectory)
        } else {
            return nil
        }
    }
    
    /// The user's Caches directory.
    static var cachesDirectory: Path {
        if let directory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last {
            return Path(directory)
        } else {
            fatalError("The Caches directory could not be found.")
        }
    }
    
    /// The application support directory typically does not exist at first.
    /// You need to create it if it doesn't exist. The getter of this variable
    /// will try to append the app bundle identifier to the path as recommended
    /// by Apple.
    static var applicationSupportDirectory: Path {
        if let directory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last {
            var appSupportPath = Path(directory)
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                appSupportPath = appSupportPath.appendingComponent(bundleIdentifier)
            }
            return appSupportPath
        } else {
            fatalError("The Application Support directory could not be found.")
        }
    }
    
    /// The user's Downloads directory, or `nil` if unavailable.
    static var downloadsDirectory: Path? {
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).last {
            return Path(documentDirectory)
        } else {
            return nil
        }
    }
    
    /// The user's Desktop directory, or `nil` if unavailable.
    static var desktopDirectory: Path? {
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).last {
            return Path(documentDirectory)
        } else {
            return nil
        }
    }
    
    /// The user's Applications directory, or `nil` if unavailable.
    static var applicationsDirectory: Path? {
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).last {
            return Path(documentDirectory)
        } else {
            return nil
        }
    }
    
    /// Changes the process's current working directory to this path.
    func becomeCurrentDirectory() {
        fileManager.changeCurrentDirectoryPath(internalPath)
    }
    
    /// Creates a directory at this path.
    ///
    /// - Parameters:
    ///   - createIntermediateDirectories: Whether to create parent directories as needed.
    ///   - attributes: Optional file attributes for the new directory.
    func createDirectory(withIntermediateDirectories createIntermediateDirectories: Bool = true, attributes: [FileAttributeKey: Any]? = nil) throws {
        try fileManager.createDirectory(at: URL(fileURLWithPath: internalPath, isDirectory: true), withIntermediateDirectories: createIntermediateDirectories, attributes: attributes)
    }
    
    /// Removes the file or directory at this path.
    func remove() throws {
        try fileManager.removeItem(at: url)
    }
    
    /// Copies the file or directory to the given destination path.
    func copy(to toPath: Path) throws {
        try fileManager.copyItem(atPath: internalPath, toPath: toPath.internalPath)
    }

    /// Copies the file or directory to the given destination string path.
    func copy(to toPath: String) throws {
        try fileManager.copyItem(atPath: internalPath, toPath: toPath)
    }

    /// Copies the file or directory to the given destination URL.
    func copy(to toURL: URL) throws {
        try fileManager.copyItem(at: url, to: toURL)
    }

    /// Safely replaces the file at this path with the file at the given path,
    /// creating a backup before the replacement.
    ///
    /// - Returns: The URL of the resulting item, or `nil` if the replacement failed.
    func safeReplace(withItemAt itemPath: Path) throws -> URL? {
        let resultingURL = try fileManager.replaceItemAt(url,
                                                         withItemAt: itemPath.url,
                                                         backupItemName: itemPath.url.lastPathComponent + ".safeReplaceBackup",
                                                         options: .usingNewMetadataOnly)
        return resultingURL
    }
    
    /// Set POSIX file permissions. Same as chmod. Octal number is recommended.
    func setPosixPermissions(_ permissions: Int) throws {
        try fileManager.setAttributes([.posixPermissions: permissions],
                                      ofItemAtPath: internalPath)
    }
}


