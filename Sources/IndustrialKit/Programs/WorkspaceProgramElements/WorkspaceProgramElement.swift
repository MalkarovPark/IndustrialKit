//
//  WorkspaceProgramElement.swift
//  IndustrialKit
//
//  Created by Artem on 01.04.2022.
//

import Foundation
import SwiftUI

/**
 A type of workspace program element that is performed to manage means of production.
 
 The element contains some action performed by the production system.
 */
public class WorkspaceProgramElement: Hashable, Identifiable
{
    public static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id == rhs.id //Identity condition by id plus element type
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var id = UUID()
    
    public init()
    {
        
    }
    
    ///Inits workspace program element by appropriate codable structure.
    public init(element_struct: WorkspaceProgramElementStruct)
    {
        if element_struct.identifier == identifier && element_struct.data.count == data_count
        {
            data_from_struct(element_struct)
        }
    }
    
    ///Inits workspace program element by appropriate identifier
    public init(element_identifier: WorkspaceProgramElementIdentifier)
    {
        data_from_struct(WorkspaceProgramElementStruct(identifier: element_identifier, data: [String]()))
    }
    
    ///Element type identifier
    public var identifier: WorkspaceProgramElementIdentifier?
    {
        return nil
    }
    
    ///Element data components count for type
    public var data_count: Int
    {
        return 0
    }
    
    /**
     Inits program element by struct.
     - Parameters:
        - struct: Appropriate codable struct.
     */
    public func data_from_struct(_ element_struct: WorkspaceProgramElementStruct)
    {
        
    }
    
    ///A string for the title in program element card.
    open var title: String
    {
        return "Title"
    }
    
    ///A string for the text in program element card.
    open var info: String
    {
        return "Info"
    }
    
    ///An image name for program element card.
    open var symbol_name: String
    {
        return "app"
    }
    
    ///An image for program element card.
    public var image: Image
    {
        return Image(systemName: symbol_name)
    }
    
    ///A color for the program element card.
    open var color: Color
    {
        return Color(.gray)
    }
    
    //MARK: - Work with file system
    ///Converts tool data to codable tool struct.
    public var file_info: WorkspaceProgramElementStruct
    {
        return WorkspaceProgramElementStruct()
    }
}

//MARK: - Modifier elements

//MARK: - Logic elements

//MARK: - ?
///A codable tool struct.
public struct WorkspaceProgramElementStruct: Codable
{
    public var identifier: WorkspaceProgramElementIdentifier?
    
    public var data: [String]
    
    public init()
    {
        data = [String]()
    }
    
    public init(identifier: WorkspaceProgramElementIdentifier, data: [String])
    {
        self.identifier = identifier
        self.data = data
    }
}

public enum ModifierCopyType: String, Codable, Equatable, CaseIterable
{
    case duplicate = "Duplicate"
    case move = "Move"
}

public enum ObserverObjectType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
}

///A workspace program element type enum.
public enum WorkspaceProgramElementIdentifier: Codable, Equatable, CaseIterable
{
    //Performer
    case robot_performer
    case tool_performer
    
    //Modifier
    case mover_modifier
    case writer_modifier
    case math_modifier
    case changer_modifier
    case observer_modifier
    case cleaner_modifier
    
    //Logic
    case jump_logic
    case comparator_logic
    case mark_logic
}
