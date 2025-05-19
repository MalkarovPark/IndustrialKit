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
public struct StateItem: Identifiable, Codable
{
    public var id = UUID()
    
    public var name: String
    public var value: String?
    public var image: String?
    
    public var children: [StateItem]?
    
    public var is_expanded = false
    
    public init(name: String, value: String? = nil, image: String? = nil, children: [StateItem]? = nil)
    {
        self.name = name
        self.value = value
        self.image = image
        self.children = children
    }
    
    // MARK: - Work with file system
    enum CodingKeys: String, CodingKey
    {
        case id
        case name
        case value
        case image
        case children
    }
    
    public init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id       = try container.decode(UUID.self, forKey: .id)
        self.name     = try container.decode(String.self, forKey: .name)
        self.value    = try container.decodeIfPresent(String.self, forKey: .value)
        self.image    = try container.decodeIfPresent(String.self, forKey: .image)
        self.children = try container.decodeIfPresent([StateItem].self, forKey: .children)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(image, forKey: .image)
        try container.encode(children, forKey: .children)
    }
}
