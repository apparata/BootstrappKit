//
//  Copyright © 2019 Apparata AB. All rights reserved.
//

import Foundation

public struct BootstrappParameter {
    
    public enum Error: Swift.Error {
        case invalidParameterType
    }
    
    public enum ParameterType: String, Codable {
        case string = "String"
        case bool = "Bool"
        case option = "Option"
    }
        
    public let name: String
    public let id: String
    public let type: ParameterType
    public let validationRegex: Regex?
    public let options: [String]

    public let defaultStringValue: String
    public let stringValue: String
    
    public let defaultBoolValue: Bool
    public let boolValue: Bool
    
    public let defaultOptionValue: Int
    public let optionValue: Int
    
    public let dependsOnParameter: String?
    
    public var anyValue: Any? {
        switch type {
        case .string: return stringValue.isEmpty ? nil : stringValue
        case .bool: return boolValue
        case .option: return options[optionValue]
        }
    }
        
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
