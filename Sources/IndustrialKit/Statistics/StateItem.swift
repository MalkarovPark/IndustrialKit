//
//  WorkspaceObjectChart.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.12.2022.
//

import Foundation

public struct StateItem: Identifiable, Codable
{
    public var id = UUID()
    
    var name: String
    var value: String?
    var image: String?
    
    var children: [StateItem]?
    
    //MARK: Init functions
    public init(name: String)
    {
        self.name = name
    }
    
    public init(name: String, value: String)
    {
        self.name = name
        self.value = value
    }
    
    public init(name: String, image: String)
    {
        self.name = name
        self.image = image
    }
    
    public init(name: String, value: String, image: String)
    {
        self.name = name
        self.value = value
        self.image = image
    }
    
    public init(name: String, children: [StateItem])
    {
        self.name = name
        
        self.children = children
    }
    
    public init(name: String, value: String, children: [StateItem])
    {
        self.name = name
        self.value = value
        
        self.children = children
    }
    
    public init(name: String, image: String, children: [StateItem])
    {
        self.name = name
        self.image = image
        
        self.children = children
    }
    
    public init(name: String, value: String, image: String, children: [StateItem])
    {
        self.name = name
        self.value = value
        self.image = image
        
        self.children = children
    }
}
