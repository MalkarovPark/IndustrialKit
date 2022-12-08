//
//  OperationsProgram.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.10.2022.
//

import Foundation

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
    
    public var name: String?
    public var codes = [OperationCode]()
    
    public var codes_count: Int
    {
        return codes.count
    }
    
    //MARK: - Code manage functions
    public func add_code(_ code: OperationCode)
    {
        codes.append(code)
        new_code_check(number: codes.count - 1)
    }
    
    public func update_code(number: Int, _ code: OperationCode)
    {
        if codes.indices.contains(number) //Checking for the presence of a point with a given number to update
        {
            codes[number] = code
            new_code_check(number: number)
        }
    }
    
    public func delete_code(number: Int) //Checking for the presence of a point with a given number to delete
    {
        if codes.indices.contains(number)
        {
            codes.remove(at: number)
        }
    }
    
    private func new_code_check(number: Int)
    {
        if codes.count > 0 && number < codes_count
        {
            if codes.last?.value ?? 0 < 0
            {
                codes[codes.count].value = 0
            }
        }
    }
    
    //MARK: - Positions program init functions
    public init()
    {
        self.name = "None"
    }
    
    public init(name: String?)
    {
        self.name = name ?? "None"
    }
}
