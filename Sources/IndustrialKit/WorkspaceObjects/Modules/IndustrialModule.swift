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
public class IndustrialModule: Identifiable, Codable, Equatable
{
    public var id = UUID()
    
    public static func == (lhs: IndustrialModule, rhs: IndustrialModule) -> Bool
    {
        lhs.name == rhs.name
    }
    
    @Published public var name = String() ///A module name.
    @Published public var description = String() ///An optional module description.
    
    //MARK: - File handling
    /**
     A module file name
     
     Uses for access contents of module package.
     */
    @Published public var package_file_name: String
    
    /**
     An additional resources files names.
     
     Used to check files in a package and during the STC package compilation process.
     
     > Such as images, models etc.
     */
    @Published public var additional_resources_names: [String]?
    
    /**
     An additional listing files names.
     
     Used to check files in a package and during the STC package compilation process.
     */
    @Published public var additional_listings_names: [String]?
    
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
        case additional_resources_names
        case additional_listings_names
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.package_file_name = try container.decode(String.self, forKey: .package_file_name)
        self.additional_resources_names = try container.decodeIfPresent([String].self, forKey: .additional_resources_names)
        self.additional_listings_names = try container.decodeIfPresent([String].self, forKey: .additional_listings_names)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(package_file_name, forKey: .package_file_name)
        try container.encodeIfPresent(additional_resources_names, forKey: .additional_resources_names)
        try container.encodeIfPresent(additional_listings_names, forKey: .additional_listings_names)
    }
}

//MARK: - Structures
//MARK: - File
/*public struct FileHolder: Equatable
{
    public static func == (lhs: FileHolder, rhs: FileHolder) -> Bool
    {
        lhs.name == rhs.name
    }
    
    var name = String()
    var data = (Any).self
}*/

//MARK: App Modules
/*public struct ChangerModule: Equatable, Codable
{
    var name = ""
    var code = ""
}*/

/*public struct ToolModule: Equatable, Codable
{
    var name = ""
    
    var operation_codes = [OperationCode]()
    
    var controller = ToolControllerModule()
    var connector = ToolConnectorModule()
}

public struct ToolControllerModule: Equatable, Codable
{
    var connect = ""
    var reset = ""
    var other = ""
    
    var statistics = StatisticsFunctionsData()
}

public struct ToolConnectorModule: Equatable, Codable
{
    var connect = ""
    var disconnect = ""
    var other = ""
    
    var statistics = StatisticsFunctionsData()
}

public struct StatisticsFunctionsData: Equatable, Codable
{
    var chart_code = ""
    var chart_code_clear = ""
    
    var state_code = ""
    var state_code_clear = ""
    
    var other_code = ""
}

public struct OperationCode: Equatable, Codable
{
    var value = 0
    var name = ""
    var symbol = "questionmark"
    
    //var code = ""
    var controller_code = ""
    var connector_code = ""
}*/
