//
//  File.swift
//  
//
//  Created by Malkarov Park on 08.12.2022.
//

import Foundation

struct StateItem: Identifiable, Codable
{
    var id = UUID()
    
    var name: String
    var value: String?
    var image: String?
    
    var children: [StateItem]?
}
