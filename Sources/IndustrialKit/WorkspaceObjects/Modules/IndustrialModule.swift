//
//  IndustrialModule.swift
//  Industrial Builder
//
//  Created by Artem on 11.04.2024.
//

import Foundation

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
    
    @Published public var name = String() ///A module name.
    @Published public var description = String() ///An optional module description.
    
    public var is_internal = false ///Defines the internal/external source of the changer code.
    
    @Published public var code_items = [CodeItem]() ///Code lisitngs of module.
    
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
     A module file name
     
     Uses for access contents of module package.
     */
    @Published public var package_file_name: String
    
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
    
    public init(name: String = String(), description: String = String(), package_file_name: String = String())
    {
        self.name = name
        self.description = description
        self.package_file_name = package_file_name
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
            
            return "\(url.absoluteString)\(package_file_name).\(extension_name)/"
        }
        catch
        {
            return nil
        }
    }
    
    //MARK: Codable handling
    enum CodingKeys: String, CodingKey
    {
        case name
        case description
        case package_file_name
        
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
        self.package_file_name = try container.decode(String.self, forKey: .package_file_name)
        
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
        try container.encode(package_file_name, forKey: .package_file_name)
        
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
