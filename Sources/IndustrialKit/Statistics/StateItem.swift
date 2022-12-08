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
}
