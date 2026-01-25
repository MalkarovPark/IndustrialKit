//
//  IndustrialModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import RealityKit

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
    
    /// A module name.
    @Published public var name = String()
    
    /// An optional module description.
    @Published public var description = String()
    
    /// Code lisitngs of module.
    @Published public var code_items = [String: String]()
    
    /// Linked components from internal modules.
    @Published public var linked_components = [String: String]()
    
    // MARK: - File handling
    /// A folder bookmark to resources access.
    nonisolated(unsafe) public static var work_folder_bookmark: Data?
    
    /// An object package extension name.
    open var extension_name: String { "module" }
    
    // MARK: - Init functions
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
    
    // MARK: Module init for in-app mounting
    /// Internal module init.
    public init(name: String = String(), description: String = String())
    {
        self.name = name
        self.description = description
    }
    
    /// External module init.
    public init(external_name: String = String())
    {
        self.name = external_name
        self.description = String()
        
        is_internal_entity = false
    }
    
    public var internal_url: String? /// An adress to package contents access.
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
    
    // MARK: - Module design functions
    /// Default code items for module design process.
    open var default_code_items: [String: String]
    {
        return [String: String]()
    }
    
    /// Default linked modules of components.
    open var default_linked_components: [String: String]
    {
        return [String: String]()
    }
    
    // MARK: - Entities handling
    private var is_internal_entity = true
    
    @MainActor private var entity: Entity?
    
    /// A scene passed to object.
    public var internal_entity_name: String
    {
        return "\(name).\(extension_name).\(scene_file_name)" // name.module.scene 6DOF.robot.scene
    }
    
    private var scene_file_name: String { "Scene" }
    
    /// A module package url of external module.
    open var package_url: URL
    {
        return URL(filePath: "")
    }
    
    @MainActor public func perform_load_entity()//(named name: String)
    {
        Task
        {
            do
            {
                if is_internal_entity
                {
                    self.entity = try await Entity(named: internal_entity_name)
                    print("🥂 Internal Loaded! (\(internal_entity_name))")
                }
                else
                {
                    self.entity = try await load_external_entity()
                    print("🥂 External Loaded! (\(name))")
                }
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
    }
    
    private func load_external_entity() async throws -> Entity
    {
        let scene_url = package_url.appendingPathComponent(scene_file_name + ".usdz")
        
        guard FileManager.default.fileExists(atPath: scene_url.path) else
        {
            throw CocoaError(.fileNoSuchFile)
        }
        
        let entity = try await Entity(contentsOf: scene_url)
        return entity
    }
    
    // MARK: - External Program Components
    #if os(macOS)
    /**
     Returns an array of program component paths used in the module.
     
     Each element of the array is a tuple containing:
     - `file`: The path to the executable file of the module.
     - `socket`: The path to the Unix socket created by the module for inter-process communication.
     */
    open var program_components_paths: [(file: String, socket: String)]
    {
        return [(file: String, socket: String)]()
    }
    
    /// Start all program components in module.
    @MainActor public func start_program_components() async
    {
        for program_components_path in program_components_paths
        {
            if await !is_socket_active(at: program_components_path.socket)
            {
                perform_terminal_app_sync(at: self.package_url.appendingPathComponent(program_components_path.file), with: [" > /dev/null 2>&1 &"])
            }
            //perform_terminal_app_sync(at: self.package_url.appendingPathComponent(program_components_path.file), with: [" > /dev/null 2>&1 &"])
        }
    }
    
    /// Stop all program components in module.
    public func stop_program_components()
    {
        for program_components_path in program_components_paths
        {
            send_via_unix_socket(at: program_components_path.socket, command: "stop")
        }
    }
    #endif
    
    // MARK: - Codable handling
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
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        try container.encode(code_items, forKey: .code_items)
        try container.encode(linked_components, forKey: .linked_components)
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
    
    // MARK: Codable handling
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
