//
//  OperationCode.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.11.2022.
//

import Foundation

class OperationCode: Identifiable, Codable, Hashable
{
    static func == (lhs: OperationCode, rhs: OperationCode) -> Bool
    {
        lhs.id == rhs.id //Identity condition by id
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var value = 0
    
    init(_ value: Int)
    {
        self.value = value
    }
}
