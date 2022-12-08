//
//  OperationCode.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.11.2022.
//

import Foundation

public class OperationCode: Identifiable, Codable, Hashable
{
    public static func == (lhs: OperationCode, rhs: OperationCode) -> Bool
    {
        lhs.id == rhs.id //Identity condition by id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var value = 0
    
    public init(_ value: Int)
    {
        self.value = value
    }
}
