//
//  OperationsProgram.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.10.2022.
//

import Foundation

/**
 A program performable by an industrial tool.
 
 Contains an array of opcodes and a custom name used for identification.
 */
public class OperationsProgram: Identifiable, Codable, Hashable
{
    public static func == (lhs: OperationsProgram, rhs: OperationsProgram) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    ///An operations program name
    public var name: String?
    
    ///An array of opertaions codes.
    public var codes = [OperationCode]()
    
    //MARK: - Init functions
    
    ///Creates a new operations program.
    public init()
    {
        self.name = "None"
    }
    
    /**
     Creates a new operations program.
     - Parameters:
        - name: A new positions program name.
     */
    public init(name: String?)
    {
        self.name = name ?? "None"
    }
    
    //MARK: - Code manage functions
    
    /**
     Add the new code to opertaions program.
     - Parameters:
        - code: An added code.
     */
    public func add_code(_ code: OperationCode)
    {
        codes.append(code)
        new_code_check(index: codes.count - 1)
    }
    
    /**
     Creates a new operations program.
     - Parameters:
        - index: Updated operation code index.
        - code: New operation code.
     */
    public func update_code(index: Int, _ code: OperationCode)
    {
        if codes.indices.contains(index)
        {
            codes[index] = code
            new_code_check(index: index)
        }
    }
    
    /**
     Checks for the presence of a code with a given index to delete.
     - Parameters:
        - index: An index of deleted code.
     */
    public func delete_code(index: Int)
    {
        if codes.indices.contains(index)
        {
            codes.remove(at: index)
        }
    }
    
    ///Returns the operations codes count.
    public var codes_count: Int
    {
        return codes.count
    }
    
    /**
     Resets code values to zero if their values are negative.
     - Parameters:
        - index: Checkable number index.
     */
    private func new_code_check(index: Int)
    {
        if codes.count > 0 && index < codes_count
        {
            if codes.last?.value ?? 0 < 0
            {
                codes[codes.count].value = 0
            }
        }
    }
}
