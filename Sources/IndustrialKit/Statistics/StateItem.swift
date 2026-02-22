//
//  StateItem.swift
//  IndustrialKit
//
//  Created by Artem on 08.12.2022.
//

import Foundation

/**
 A storage for state info.
 */
public class StateItem: Hashable, Identifiable, ObservableObject, Codable
{
    public static func == (lhs: StateItem, rhs: StateItem) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    @Published public var name: String
    @Published public var value: String?
    @Published public var symbol_name: String?
    
    @Published public var children: [StateItem]?
    
    public init(
        name: String,
        value: String? = nil,
        symbol_name: String? = nil,
        
        children: [StateItem]? = nil
    )
    {
        self.name = name
        self.value = value
        self.symbol_name = symbol_name
        
        self.children = children
    }
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case value
        case symbol_name
        
        case children
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.value = try container.decode(String.self, forKey: .value)
        self.symbol_name = try container.decode(String.self, forKey: .symbol_name)
        
        self.children = try container.decode([StateItem].self, forKey: .children)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(symbol_name, forKey: .symbol_name)
        
        try container.encodeIfPresent(children, forKey: .children)
    }
}
