//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

/// A user-facing template parameter that is injected into the rendering context.
///
/// Parameters are immutable value types. Use the `withValue()` copy methods to
/// produce a new parameter with an updated value.
public struct BootstrappParameter {

    /// Errors that can occur when decoding a parameter.
    public enum Error: Swift.Error {
        /// The `type` field does not match any known ``ParameterType``.
        case invalidParameterType
    }

    /// The data type of a template parameter.
    public enum ParameterType: String, Codable {
        /// A free-text string value, optionally validated by a regex.
        case string = "String"
        /// A boolean toggle.
        case bool = "Bool"
        /// A selection from a fixed list of string options.
        case option = "Option"
    }

    /// The human-readable display name of the parameter.
    public let name: String

    /// The identifier used as the key in the template rendering context.
    public let id: String

    /// The data type of this parameter.
    public let type: ParameterType

    /// An optional regex used to validate string parameter values.
    public let validationRegex: Regex?

    /// The available choices for `.option` type parameters.
    public let options: [String]

    /// The default value for `.string` type parameters.
    public let defaultStringValue: String

    /// The current value for `.string` type parameters.
    public let stringValue: String

    /// The default value for `.bool` type parameters.
    public let defaultBoolValue: Bool

    /// The current value for `.bool` type parameters.
    public let boolValue: Bool

    /// The default selected index for `.option` type parameters.
    public let defaultOptionValue: Int

    /// The current selected index for `.option` type parameters.
    public let optionValue: Int

    /// The `id` of another parameter that this parameter depends on.
    /// When set, this parameter is only relevant when the dependency is truthy.
    public let dependsOnParameter: String?

    /// Returns the current value as `Any?`, according to the parameter's type.
    ///
    /// - For `.string`: the string value, or `nil` if empty.
    /// - For `.bool`: the boolean value.
    /// - For `.option`: the selected option string from ``options``.
    public var anyValue: Any? {
        switch type {
        case .string: return stringValue.isEmpty ? nil : stringValue
        case .bool: return boolValue
        case .option: return options[optionValue]
        }
    }
        
    /// Creates a new parameter with all fields specified explicitly.
    public init(name: String,
                id: String,
                type: ParameterType,
                validationRegex: Regex?,
                options: [String],
                defaultStringValue: String,
                defaultBoolValue: Bool,
                defaultOptionValue: Int,
                stringValue: String = "",
                boolValue: Bool = false,
                optionValue: Int = 0,
                dependsOnParameter: String? = nil) {
        self.name = name
        self.id = id
        self.type = type
        self.validationRegex = validationRegex
        self.options = options
        self.defaultStringValue = defaultStringValue
        self.stringValue = stringValue
        self.defaultBoolValue = defaultBoolValue
        self.boolValue = boolValue
        self.defaultOptionValue = defaultOptionValue
        self.optionValue = optionValue
        self.dependsOnParameter = dependsOnParameter
    }
    
    /// Returns a copy of this parameter with an updated string value.
    public func withValue(value: String) -> BootstrappParameter {
        BootstrappParameter(name: name,
                            id: id,
                            type: type,
                            validationRegex: validationRegex,
                            options: options,
                            defaultStringValue: defaultStringValue,
                            defaultBoolValue: defaultBoolValue,
                            defaultOptionValue: defaultOptionValue,
                            stringValue: value,
                            dependsOnParameter: dependsOnParameter)
    }

    /// Returns a copy of this parameter with an updated boolean value.
    public func withValue(value: Bool) -> BootstrappParameter {
        BootstrappParameter(name: name,
                            id: id,
                            type: type,
                            validationRegex: validationRegex,
                            options: options,
                            defaultStringValue: defaultStringValue,
                            defaultBoolValue: defaultBoolValue,
                            defaultOptionValue: defaultOptionValue,
                            boolValue: value,
                            dependsOnParameter: dependsOnParameter)
    }
    
    /// Returns a copy of this parameter with an updated option index value.
    public func withValue(value: Int) -> BootstrappParameter {
        BootstrappParameter(name: name,
                            id: id,
                            type: type,
                            validationRegex: validationRegex,
                            options: options,
                            defaultStringValue: defaultStringValue,
                            defaultBoolValue: defaultBoolValue,
                            defaultOptionValue: defaultOptionValue,
                            optionValue: value,
                            dependsOnParameter: dependsOnParameter)
    }
    
}

extension BootstrappParameter: Hashable, Identifiable {
        
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: BootstrappParameter, rhs: BootstrappParameter) -> Bool {
        lhs.id == rhs.id
    }
}

extension BootstrappParameter: Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case type
        case validationRegex
        case defaultValue = "default"
        case options
        case value
        case dependsOn
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ParameterType.self, forKey: .type)
        if let regex = try container.decodeIfPresent(String.self, forKey: .validationRegex) {
            validationRegex = Regex(regex)
        } else {
            validationRegex = nil
        }
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []

        if type == .string {
            let defaultStringValue = try container.decodeIfPresent(String.self, forKey: .defaultValue) ?? ""
            self.defaultStringValue = defaultStringValue
            stringValue = try container.decodeIfPresent(String.self, forKey: .value) ?? defaultStringValue
            defaultBoolValue = false
            boolValue = false
            defaultOptionValue = 0
            optionValue = 0
        } else if type == .bool {
            defaultStringValue = ""
            stringValue = ""
            let defaultBoolValue = try container.decodeIfPresent(Bool.self, forKey: .defaultValue) ?? false
            self.defaultBoolValue = defaultBoolValue
            boolValue = try container.decodeIfPresent(Bool.self, forKey: .value) ?? defaultBoolValue
            defaultOptionValue = 0
            optionValue = 0
        } else if type == .option {
            defaultStringValue = ""
            stringValue = ""
            defaultBoolValue = false
            boolValue = false
            let defaultOptionValue = try container.decodeIfPresent(Int.self, forKey: .defaultValue) ?? 0
            self.defaultOptionValue = defaultOptionValue
            optionValue = try container.decodeIfPresent(Int.self, forKey: .value) ?? defaultOptionValue
        } else {
            throw Error.invalidParameterType
        }
        
        dependsOnParameter = try container.decodeIfPresent(String.self, forKey: .dependsOn)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(validationRegex?.pattern, forKey: .id)
        try container.encodeIfPresent(options, forKey: .options)

        if type == .string {
            try container.encodeIfPresent(defaultStringValue, forKey: .defaultValue)
            try container.encodeIfPresent(stringValue, forKey: .value)
        } else if type == .bool {
            try container.encodeIfPresent(defaultBoolValue, forKey: .defaultValue)
            try container.encodeIfPresent(boolValue, forKey: .value)
        } else if type == .option {
            try container.encodeIfPresent(defaultOptionValue, forKey: .defaultValue)
            try container.encodeIfPresent(optionValue, forKey: .value)
        }
        
        try container.encodeIfPresent(dependsOnParameter, forKey: .dependsOn)
    }
}
