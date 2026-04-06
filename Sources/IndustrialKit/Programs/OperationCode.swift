//
//  OperationCode.swift
//  IndustrialKit
//
//  Created by Artem on 08.11.2022.
//

import Foundation
import SwiftUI

/// A discrete operation command represented by an integer value.
///
/// `OperationCode` defines a single executable unit within an
/// ``OperationProgram``. Each instance encapsulates a numeric code
/// that corresponds to a tool-specific action.
///
/// The class supports:
/// - Identification and hashing for collection usage
/// - Performing state tracking for UI and runtime visualization
/// - Serialization for persistence and transfer
///
/// Operation codes are typically interpreted by a tool or controller,
/// where the numeric value maps to a predefined operation.
///
public class OperationCode: Identifiable, Codable, Hashable, ObservableObject, @unchecked Sendable
{
    public let id: UUID = UUID()
    
    public static func == (lhs: OperationCode, rhs: OperationCode) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// Operation code value.
    @Published public var value = 0
    
    // MARK: - Initializer
    /// The numeric value of the operation code.
    ///
    /// This value is interpreted by the device as a specific command.
    public init(_ value: Int)
    {
        self.value = value
    }
    
    // MARK: - UI
    @Published public var performing_state: PerformingState = .none
    
    // MARK: - File Hanlding
    enum CodingKeys: String, CodingKey
    {
        case value
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        value = try container.decode(Int.self, forKey: .value)
        performing_state = .none
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(value, forKey: .value)
    }
}

/// A descriptor that provides semantic information about an operation code.
///
/// `OperationCodeInfo` defines metadata associated with a numeric
/// ``OperationCode`` value, enabling human-readable representation
/// and UI integration.
///
/// The descriptor includes:
/// - A numeric value corresponding to the operation code
/// - A human-readable name
/// - A system symbol identifier for UI rendering
/// - A textual description of the operation
///
/// Instances of this type are typically used to define the set of
/// supported operations for a specific device or module.
public class OperationCodeInfo: Identifiable, Codable, Hashable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: OperationCodeInfo, rhs: OperationCodeInfo) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// The numeric value of the operation code.
    public var value: Int
    
    /// A human-readable name of the operation.
    public var name: String
    
    /// A system symbol name used for UI representation.
    ///
    /// This value is typically used with SF Symbols.
    public var symbol_name: String
    
    /// A textual description of the operation.
    public var description: String
    
    // MARK: - Initializer
    public init(
        value: Int = 0,
        name: String = "",
        symbol_name: String = "",
        description: String = ""
    )
    {
        self.value = value
        self.name = name
        self.symbol_name = symbol_name
        self.description = description
    }
    
    // MARK: - UI
    /// A system image representing the operation code.
    ///
    /// The image is created using the ``symbol_name`` value.
    public var image: Image
    {
        return Image(systemName: symbol_name)
    }
    
    // MARK: - File Hanlding
    enum CodingKeys: String, CodingKey
    {
        case value
        case name
        case symbol_name
        case description
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        value = try container.decode(Int.self, forKey: .value)
        name = try container.decode(String.self, forKey: .name)
        symbol_name = try container.decode(String.self, forKey: .symbol_name)
        description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(value, forKey: .value)
        try container.encode(name, forKey: .name)
        try container.encode(symbol_name, forKey: .symbol_name)
        try container.encode(description, forKey: .description)
    }
}
