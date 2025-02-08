//
//  OperationCode.swift
//  IndustrialKit
//
//  Created by Artem on 08.11.2022.
//

import Foundation

/**
 A type that contains the numerical value of the operation code performed by the tool in production.
 
 A program unit with an integer. This class is identifiable in an array.
 */
public class OperationCode: Identifiable, Codable, Hashable
{
    public static func == (lhs: OperationCode, rhs: OperationCode) -> Bool
    {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    /// Operation code value.
    public var value = 0
    
    /**
     Creates a performable operation code element.
     - Parameters:
        - value: A new operation code value.
     */
    public init(_ value: Int)
    {
        self.value = value
    }
}
