//
//  OperationCode.swift
//  IndustrialKit
//
//  Created by Artem on 08.11.2022.
//

import Foundation
import SwiftUI

/**
 A type that contains the numerical value of the operation code performed by the tool in production.
 
 A program unit with an integer. This class is identifiable in an array.
 */
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
    
    // MARK: - Init functions
    /**
     Creates a performable operation code element.
     - Parameters:
        - value: A new operation code value.
     */
    public init(_ value: Int)
    {
        self.value = value
    }
    
    // MARK: - UI functions
    @Published public var performing_state: PerformingState = .none
    
    // MARK: - File Data
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

/**
 Provides information about the operation code.
 
 An array of them determines the opcode values ​​available for a given device.
 */
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
    
    /// Operation code value.
    public var value: Int
    
    /// Operation code name.
    public var name: String
    
    /// Operation code symbol.
    public var symbol_name: String
    
    /// Operation code description.
    public var description: String
    
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
    
    public var image: Image
    {
        return Image(systemName: symbol_name)
    }
    
    // MARK: - File Data
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
