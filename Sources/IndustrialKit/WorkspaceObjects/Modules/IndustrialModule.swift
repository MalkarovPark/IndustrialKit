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
    
    ///Code lisitngs of module.
    @Published public var code_items = [String: String]()
    
    ///Linked components from internal modules.
    @Published public var linked_components = [String: String]()
    
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
    /**
     New module init.
     
     For new designed modules.
     */
    public init(new_name: String = String(), description: String = String())
    {
        self.name = new_name
        self.description = description
        
        self.code_items = default_code_items
        
        self.linked_components = default_linked_components
    }
    
    //MARK: Module init for in-app mounting
    ///Internal module init.
    public init(name: String = String(), description: String = String())
    {
        self.name = name
        self.description = description
    }
    
    ///External module init.
    public init(external_name: String = String())
    {
        self.name = external_name
        self.description = String()
        
        //import_external_resources()
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
    
    //MARK: - Designer functions
    ///Default code items for module design process.
    open var default_code_items: [String: String]
    {
        return [String: String]()
    }
    
    ///Default linked modules of components.
    open var default_linked_components: [String: String]
    {
        return [String: String]()
    }
    
    //MARK: - Components
    ///A scene passed to object.
    open var node = SCNNode()
    
    //MARK: - Import functions
    ///A module package url of external module.
    open var package_url: URL
    {
        return URL(filePath: "")
    }
    
    ///A scene of external module passed to object.
    open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    /**
     Builds model node by description without external scene.
     
     Name of the scene corresponds to name of the module.
     */
    open func node_by_description()
    {
        no_model_node()
    }
    
    ///Builds a filler node for object without model description.
    open func no_model_node()
    {
        //Build filler model node
        node.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        node.geometry?.firstMaterial?.lightingModel = .physicallyBased
        
        //node.name = scene_node_name
    }
    
    ///Imports data from info header file of module.
    /*open func import_external_resources()
    {
        //import_info()
        //import_external_node(external_scene_url)
    }*/
    
    //MARK: - Listing elements
    open var class_name: String { name.code_correct_format } ///A class name of module code.
    open var scene_code_name: String { (main_scene_name ?? "\(name).scn").code_correct_format } ///A class SCNScene variable name.
    
    //MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case description
        
        case is_internal
        case code_items
        case linked_components
        
        case resources_names
        case main_scene_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        
        self.code_items = try container.decode([String: String].self, forKey: .code_items)
        self.linked_components = try container.decode([String: String].self, forKey: .linked_components)
        
        self.resources_names = try container.decodeIfPresent([String].self, forKey: .resources_names)
        self.main_scene_name = try container.decodeIfPresent(String.self, forKey: .main_scene_name)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        try container.encode(code_items, forKey: .code_items)
        try container.encode(linked_components, forKey: .linked_components)
        
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
