//
//  OperationProgram.swift
//  IndustrialKit
//
//  Created by Artem on 28.10.2022.
//

import Foundation

/// A named sequence of operation codes executed by a production device.
///
/// `OperationProgram` defines an ordered set of ``OperationCode`` instances
/// representing discrete commands performed by tool.
///
/// Unlike position-based programs, this type operates on symbolic or numeric
/// operation codes that map to tool-specific actions.
///
/// The program provides:
/// - Sequential execution of operation codes
/// - State management for performing lifecycle
/// - Basic editing operations (add, update, delete)
/// - Serialization for persistence and transfer
///
/// This abstraction is typically used for tools or devices that operate
/// via command-based control rather than spatial trajectories.
///
/// Equality between programs is determined by their ``name``.
///
public class OperationProgram: Identifiable, Codable, Equatable, ObservableObject
{
    public let id: UUID = UUID()
    
    public static func == (lhs: OperationProgram, rhs: OperationProgram) -> Bool
    {
        return lhs.name == rhs.name // Identity condition by names
    }
    
    /// A human-readable name of the operation program.
    ///
    /// The name is used as the primary identity condition when comparing programs.
    public var name: String
    
    /// An ordered collection of operation codes.
    ///
    /// Each code represents a discrete command executed by a device.
    @Published public var codes = [OperationCode]()
    
    // MARK: - Initializer
    /// Creates a new operation program.
    ///
    /// - Parameter name: A human-readable program name. Defaults to `"None"`.
    public init(name: String = "None")
    {
        self.name = name
    }
    
    // MARK: - Code Management
    /// Appends a new operation code to the program.
    ///
    /// - Parameter code: An operation code to add.
    public func add_code(_ code: OperationCode)
    {
        codes.append(OperationCode(code.value))
    }
    
    /// Updates an operation code at the specified index.
    ///
    /// - Parameters:
    ///   - index: The position of the code to update.
    ///   - code: A new operation code.
    public func update_code(index: Int, _ code: OperationCode)
    {
        if codes.indices.contains(index)
        {
            codes[index] = code
        }
    }
    
    /// Removes an operation code at the specified index, if it exists.
    ///
    /// - Parameter index: The index of the code to remove.
    public func delete_code(index: Int)
    {
        if codes.indices.contains(index)
        {
            codes.remove(at: index)
        }
    }
    
    /// The number of operation codes contained in the program.
    public var codes_count: Int
    {
        return codes.count
    }
    
    /// Resets the performing state of all operation codes to `.none`.
    ///
    /// This method is typically used before starting program performing.
    public func reset_codes_states()
    {
        for code in codes
        {
            code.performing_state = .none
        }
    }
    
    // MARK: - File Hanlding
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
