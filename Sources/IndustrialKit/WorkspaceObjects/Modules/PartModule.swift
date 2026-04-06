//
//  PartModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

/// A module that defines a passive component of a production environment.
///
/// `PartModule` extends ``IndustrialModule`` by providing configuration
/// for non-actuated elements within a workspace.
///
/// Unlike robots and tools, a part module does not define performing logic
/// or device interaction. Instead, it represents static or externally
/// manipulated objects used in production processes.
///
/// The module encapsulates:
/// - A visual representation of the part
/// - Resource packaging for simulation
/// - External module loading support
///
/// Part modules are used to model workpieces, fixtures,
/// and environmental elements within a production system.
/// 
open class PartModule: IndustrialModule
{
    // MARK: - Initialization
    // MARK: Module init functions for design
    /// Creates a part module for design-time configuration.
    ///
    /// - Parameters:
    ///   - new_name: A module identifier.
    ///   - description: A textual description of the module.
    public override init(
        new_name: String,
        description: String = String()
    )
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init functions for in-app mounting
    /// Creates a part module for internal runtime usage.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    public override init(
        name: String = String(),
        description: String = String()
    )
    {
        super.init(name: name, description: description)
    }
    
    /// Creates a part module from an external package.
    ///
    /// - Parameter external_name: A module identifier.
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
    }
    
    /// A file extension representing the part module package format.
    open override var file_extension_name: String { "part" }
    
    // MARK: - Components
    /// A file name of the USDZ entity used during module design.
    ///
    /// Defines the visual representation of the part
    /// used in simulation and rendering.
    @Published public var entity_file_name: String?
    
    // MARK: - Import functions
    open override var package_url: URL
    {
        do
        {
            var is_stale = false
            var local_url = try URL(resolvingBookmarkData: ProductionObject.modules_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return local_url
            }
            
            local_url = local_url.appendingPathComponent("\(name).part")
            
            return local_url
        }
        catch
        {
            //print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    /// A lazily loaded external module metadata representation.
    ///
    /// Attempts to read and decode module information
    /// from the external package on access.
    public var external_module_info: PartModule?
    {
        do
        {
            let info_url = package_url.appendingPathComponent("/Info")
            
            if FileManager.default.fileExists(atPath: info_url.path)
            {
                return try JSONDecoder().decode(PartModule.self, from: try Data(contentsOf: info_url))
            }
        }
        catch
        {
            //print(error.localizedDescription)
        }
        
        return nil
    }
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case entity_file_name
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.entity_file_name = try container.decodeIfPresent(String.self, forKey: .entity_file_name)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(entity_file_name, forKey: .entity_file_name)
        
        try super.encode(to: encoder)
    }
}
