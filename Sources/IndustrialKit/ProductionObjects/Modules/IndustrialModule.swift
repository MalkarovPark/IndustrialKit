//
//  IndustrialModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import RealityKit

/// A base representation of a modular industrial production component.
///
/// `IndustrialModule` defines a reusable unit that encapsulates
/// structure, resources, and integration logic of a production object.
///
/// A module provides:
/// - A named identity and descriptive metadata
/// - Access to packaged resources (internal or external)
/// - A 3D entity representation for simulation
/// - Integration points for program components and runtime execution
///
/// Modules can be bundled within the application or loaded from external sources,
/// enabling extensibility of the production system without recompilation.
///
/// Subclass `IndustrialModule` to implement domain-specific equipment modules.
///
open class IndustrialModule: Identifiable, Codable, Equatable, ObservableObject
{
    public var id = UUID()
    
    public static func == (lhs: IndustrialModule, rhs: IndustrialModule) -> Bool
    {
        lhs.name == rhs.name
    }
    
    /// A human-readable name of the module.
    ///
    /// The name is used for identification, file resolution,
    /// and integration within the workspace.
    @Published public var name = String()
    
    /// A textual description of the module.
    ///
    /// Provides additional information about module purpose,
    /// configuration, or usage.
    @Published public var description = String()
    
    // MARK: - File Handling
    /// A security-scoped bookmark used to access module resources.
    ///
    /// This bookmark provides persistent access to the working directory
    /// containing external module packages.
    nonisolated(unsafe) public static var work_folder_bookmark: Data?
    
    /// A file extension representing the module package format.
    ///
    /// Subclasses override this value to define custom module types.
    open var file_extension_name: String { "module" }
    
    // MARK: - Module init functions for design
    /// Creates a new module for design-time configuration.
    ///
    /// - Parameters:
    ///   - new_name: A module identifier.
    ///   - description: A textual description of the module.
    public init(
        new_name: String = String(),
        description: String = String()
    )
    {
        self.name = new_name
        self.description = description
    }
    
    // MARK: Module init functions for in-app mounting
    /// Creates a module instance for internal runtime usage.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    public init(
        name: String = String(),
        description: String = String()
    )
    {
        self.name = name
        self.description = description
    }
    
    /// Creates a module instance representing an external package.
    ///
    /// - Parameter external_name: A module identifier loaded from external source.
    public init(
        external_name: String = String()
    )
    {
        self.name = external_name
        self.description = String()
        
        is_internal_entity = false
    }
    
    /// A resolved internal URL to the module package contents.
    ///
    /// The URL is constructed using the stored bookmark and module name.
    /// Returns `nil` if the bookmark is invalid or stale.
    public var internal_url: String?
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
            
            return "\(url.absoluteString)\(name).\(file_extension_name)/"
        }
        catch
        {
            return nil
        }
    }
    
    // MARK: - Entity Handling
    /// Indicates whether the module uses an internal entity resource.
    private var is_internal_entity = true
    
    /// A 3D entity representing the module in a scene.
    ///
    /// The entity is loaded asynchronously and may be `nil` until loading completes.
    @MainActor public var entity: Entity?
    
    /// A name of the internal entity resource.
    ///
    /// The name is constructed using module naming conventions
    /// and is used for resource lookup in bundled assets.
    public var internal_entity_name: String
    {
        return "\(name).\(file_extension_name).\(scene_file_name)" // name.module.scene 6DOF.robot.scene
    }
    
    /// A base name of the scene file associated with the module.
    private var scene_file_name: String { "Scene" }
    
    /// A URL pointing to the external module package.
    ///
    /// Subclasses override this property to provide actual package location.
    open var package_url: URL
    {
        return URL(filePath: "")
    }
    
    /// Asynchronously loads the module entity.
    ///
    /// The method determines whether the module is internal or external
    /// and loads the corresponding entity resource.
    ///
    /// - Parameter completion: A closure called after loading completed.
    @MainActor public func perform_load_entity(_ completion: @escaping () -> Void = {}) //@escaping @Sendable (Result<Void, Error>) -> Void)
    {
        Task
        {
            do
            {
                if is_internal_entity
                {
                    self.entity = try await Entity(named: internal_entity_name)
                    //print("🥂 Internal Loaded! (\(internal_entity_name))")
                    
                    completion()
                }
                else
                {
                    self.entity = try await load_external_entity()
                    //print("🥂 External Loaded! (\(name))")
                    
                    completion()
                }
            }
            catch
            {
                //print(error.localizedDescription)
                completion()
            }
        }
    }
    
    /// Performs asynchronous entity loading using Swift concurrency.
    @MainActor func perform_load_entity_async() async
    {
        await withCheckedContinuation
        { continuation in
            perform_load_entity
            {
                continuation.resume()
            }
        }
    }
    
    /// Loads an entity from an external module package.
    ///
    /// - Returns: A loaded `Entity`.
    /// - Throws: An error if the resource is missing or cannot be loaded.
    @MainActor private func load_external_entity() async throws -> Entity
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
    /// A list of executable program components associated with the module.
    ///
    /// Each element defines:
    /// - `file`: Path to the executable
    /// - `socket`: Path to the communication socket
    ///
    /// These components provide runtime logic and device interaction.
    open var program_component_paths: [(file: String, socket: String)]
    {
        return [(file: String, socket: String)]()
    }
    
    /// Starts all program components associated with the module.
    ///
    /// Each component is launched if its communication socket is not active.
    @MainActor public func start_program_components() async
    {
        for program_components_path in program_component_paths
        {
            if await !is_socket_active(at: program_components_path.socket)
            {
                perform_terminal_app_sync(at: self.package_url.appendingPathComponent(program_components_path.file), with: [" > /dev/null 2>&1 &"])
            }
            //perform_terminal_app_sync(at: self.package_url.appendingPathComponent(program_components_path.file), with: [" > /dev/null 2>&1 &"])
        }
    }
    
    /// Stops all running program components.
    ///
    /// Sends a termination command to each component via its socket.
    public func stop_program_components()
    {
        for program_components_path in program_component_paths
        {
            send_via_unix_socket(at: program_components_path.socket, command: "stop")
        }
    }
    #endif
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case name
        case description
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

//MARK: - Code Item
/// A named code fragment used in module generation.
///
/// `CodeItem` represents a reusable unit of source code that can be
/// inserted into generated modules during compilation or assembly.
///
/// Code items enable modular construction of program logic,
/// allowing dynamic composition of executable behavior.
///
public class CodeItem: Codable, Equatable
{
    public static func == (lhs: CodeItem, rhs: CodeItem) -> Bool
    {
        lhs.name == rhs.name
    }
    
    /// Creates a code item with a name and source code.
    ///
    /// - Parameters:
    ///   - name: A code block identifier.
    ///   - code: A textual representation of source code.
    public init(
        name: String = String(),
        code: String = String()
    )
    {
        self.name = name
        self.code = code
    }
    
    /// A name of the code item.
    ///
    /// Used for identification and referencing during module assembly.
    @Published public var name = String()
    
    /// A textual representation of the code block.
    ///
    /// Contains source code inserted into generated modules.
    @Published public var code = String()
    
    // MARK: File Data
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
