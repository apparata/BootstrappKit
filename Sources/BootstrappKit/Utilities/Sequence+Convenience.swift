//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public extension Sequence {

    /// Filters elements where the value at the given key path satisfies a condition.
    func filterByProperty<T>(_ keyPath: KeyPath<Element, T>, where condition: (T) -> Bool) -> [Element] {
        return filter { element in
            let value = element[keyPath: keyPath]
            return condition(value)
        }
    }

    /// Filters elements where the string value at the given key path matches a regex.
    func filterByProperty(_ keyPath: KeyPath<Element, String>, matching regex: Regex) -> [Element] {
        return filterByProperty(keyPath, where: { regex.isMatch($0) })
    }

    /// Returns the sequence sorted by the comparable value at the given key path.
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
