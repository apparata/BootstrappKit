//
//  Copyright © 2015 Apparata AB. All rights reserved.
//

import Foundation

/// Errors thrown when parsing a ``VersionNumber`` from a string.
public enum VersionNumberError: Error {
    /// The string does not match the expected `\d+(\.\d+)+` format.
    case invalidVersionNumber
}

/// Represents a version number on the form \d+(\.\d+)+
///
/// - Example:
/// ```
/// let v1 = try? VersionNumber("1.2.3")
/// let v2 = VersionNumber(parts: [1, 5, 2])
/// let v3 = VersionNumber(parts: 1, 5, 2, 1)
/// v1 == v2
/// v1 < v2
/// v1 > v2
/// v2 == v3
/// v2 < v3
/// v2 > v3
/// ```
public struct VersionNumber: Comparable, Codable {
    
    static let regex: Regex = "^\\d+(?:\\.(?:\\d+))+$"
    
    /// The individual numeric components of the version (e.g. `[1, 2, 3]` for `"1.2.3"`).
    let parts: [Int]

    /// Creates a version number from variadic integer parts.
    public init(parts: Int...) {
        self.parts = parts
    }

    /// Creates a version number from an array of integer parts.
    public init(parts: [Int]) {
        self.parts = parts
    }

    /// Parses a version string in the format `"major.minor.patch"` (or more components).
    ///
    /// - Throws: ``VersionNumberError/invalidVersionNumber`` if the string doesn't
    ///   match the expected `\d+(\.\d+)+` pattern.
    public init(_ versionString: String) throws {
        guard VersionNumber.regex.isMatch(versionString) else {
            throw VersionNumberError.invalidVersionNumber
        }
        parts = versionString.components(separatedBy: ".").compactMap { Int($0) }
    }
}

// MARK: Object Description

extension VersionNumber: CustomStringConvertible {
    
    /// The dot-separated string representation of the version (e.g. `"1.2.3"`).
    public var string: String {
        return parts.map({ String($0) }).joined(separator: ".")
    }
    
    public var description: String {
        return string
    }
}

// MARK: Hashable

extension VersionNumber: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}

// MARK: Comparable

/// Compares two version numbers component by component, with fewer parts being "less than".
public func <(lhs: VersionNumber, rhs: VersionNumber) -> Bool {
    for i in 0..<min(lhs.parts.count, rhs.parts.count) {
        if lhs.parts[i] == rhs.parts[i] {
            continue
        } else if lhs.parts[i] < rhs.parts[i] {
            return true
        } else {
            return false
        }
    }
    return lhs.parts.count < rhs.parts.count
}

// MARK: Equatable

/// Two version numbers are equal when they have the same number of parts and all parts match.
public func ==(lhs: VersionNumber, rhs: VersionNumber) -> Bool {
    if lhs.parts.count != rhs.parts.count {
        return false
    }
    for i in 0..<lhs.parts.count {
        if lhs.parts[i] != rhs.parts[i] {
            return false
        }
    }
    return true
}

