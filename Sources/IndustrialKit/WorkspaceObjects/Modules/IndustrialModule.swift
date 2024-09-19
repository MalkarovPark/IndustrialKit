//
//  IndustrialModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import SceneKit

/**
 A base class of industrial production object.
 
 Sets parameters of the model and links them with the components of the package module.
 */
open class IndustrialModule: Identifiable, Codable, Equatable, ObservableObject
{
    public var id = UUID()
    
    public static func == (lhs: IndustrialModule, rhs: IndustrialModule) -> Bool
    {
        lhs.name == rhs.name
    }
    
    ///A module name.
    @Published public var name = String()
    
    ///An optional module description.
    @Published public var description = String()
    
    ///Defines the internal/external source of the code.
    public var is_internal = false
    
    ///Code lisitngs of module.
    @Published public var code_items = [CodeItem]()
    
    /*public var code_items_names: [String] ///Code items names.
    {
        var names = [String]()
        for code_item in code_items
        {
            names.append(code_item.name)
        }
        
        return names
    }*/
    
    //MARK: - File handling
    /**
     An additional resources files names.
     
     Used to check files in a package and during the STC package compilation process.
     
     > Such as images, scenes etc.
     */
    @Published public var resources_names: [String]?
    
    /**
     A main scene file name of visual model.
     
     > This, all other visual components are used by the main scene.
     */
    @Published public var main_scene_name: String?
    
    public static var work_folder_bookmark: Data? ///A folder bookmark to resources access.
    
    open var extension_name: String { "module" } ///An object package extension name.
    
    //MARK: - Init functions
    public init(name: String = String(), description: String = String(), is_internal: Bool = true)
    {
        self.name = name
        self.description = description
        self.is_internal = is_internal
    }
    
    ///External init.
    public init(external_name: String = String())
    {
        self.name = external_name
        self.description = String()
        self.is_internal = false
        
        external_import()
    }
    
    public var internal_url: String? ///An adress to package contents access.
    {
        do
        {
            var is_stale = false
            
            let url = try URL(resolvingBookmarkData: IndustrialModule.work_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale
            else
            {
                return nil
            }
            
            return "\(url.absoluteString)\(name).\(extension_name)/"
        }
        catch
        {
            return nil
        }
    }
    
    //MARK: - Components
    ///A scene passed to object.
    open var node = SCNNode()
    
    //MARK: - Import functions
    ///Imports module components for external module.
    open func external_import()
    {
        node = external_node
    }
    
    ///A scene of external module passed to object.
    open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case description
        
        case is_internal
        case code_items
        
        case resources_names
        case main_scene_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        
        self.is_internal = try container.decode(Bool.self, forKey: .is_internal)
        self.code_items = try container.decode([CodeItem].self, forKey: .code_items)
        
        self.resources_names = try container.decodeIfPresent([String].self, forKey: .resources_names)
        self.main_scene_name = try container.decodeIfPresent(String.self, forKey: .main_scene_name)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        try container.encode(is_internal, forKey: .is_internal)
        try container.encode(code_items, forKey: .code_items)
        
        try container.encodeIfPresent(resources_names, forKey: .resources_names)
        try container.encodeIfPresent(main_scene_name, forKey: .main_scene_name)
    }
}

//MARK: - Code struct
/**
 A named text block of code that is inserted into a module during compilation.
 */
public class CodeItem: Codable, Equatable
{
    public static func == (lhs: CodeItem, rhs: CodeItem) -> Bool
    {
        lhs.name == rhs.name
    }
    
    public init(name: String = String(), code: String = String())
    {
        self.name = name
        self.code = code
    }
    
    @Published public var name = String()
    @Published public var code = String()
    
    //MARK: Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.code = try container.decode(String.self, forKey: .code)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
    }
}
