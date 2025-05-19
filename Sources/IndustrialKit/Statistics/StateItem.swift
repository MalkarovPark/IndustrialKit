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
    
    // MARK: Init function
    public init(name: String, value: String? = nil, image: String? = nil, children: [StateItem]? = nil)
    {
        self.name = name
        self.value = value
        self.image = image
        self.children = children
    }
}
