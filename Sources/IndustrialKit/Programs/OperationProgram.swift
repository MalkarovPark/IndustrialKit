//
//  OperationProgram.swift
//  IndustrialKit
//
//  Created by Artem on 28.10.2022.
//

import Foundation

/**
 A type of named set of operation codes performed by an industrial robot.
 
 Contains an array of opcodes and a custom name used for identification.
 */
public class OperationProgram: Identifiable, Codable, Equatable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: OperationProgram, rhs: OperationProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// An operations program name
    public var name: String
    
    /// An array of opertaions codes.
    @Published public var codes = [OperationCode]()
    
    // MARK: - Init functions
    
    /**
     Creates a new operations program.
     - Parameters:
        - name: A new program name.
     */
    public init(name: String = "None")
    {
        self.name = name
    }
    
    // MARK: - Code manage functions
    /**
     Add the new code to opertaions program.
     - Parameters:
        - code: An added code.
     */
    public func add_code(_ code: OperationCode)
    {
        codes.append(OperationCode(code.value))
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
    
    /// Returns the operations codes count.
    public var codes_count: Int
    {
        return codes.count
    }
    
    /// Resets the performing state of all operation codes to the `.none` state.
    public func reset_codes_states()
    {
        for code in codes
        {
            code.performing_state = .none
        }
    }
    
    // MARK: - File Data
    private enum CodingKeys: String, CodingKey
    {
        case name
        case codes
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.codes = try container.decode([OperationCode].self, forKey: .codes)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(codes, forKey: .codes)
    }
}
