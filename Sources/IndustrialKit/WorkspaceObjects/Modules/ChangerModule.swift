//
//  ChangerModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

open class ChangerModule: IndustrialModule
{
    // MARK: - Module init functions for design
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init functions for in-app mounting
    /// Internal module init.
    public init(name: String = String(), description: String = String(), change_func: @escaping (inout [Float]) throws -> Void) //public init(name: String = String(), description: String = String(), change_func: @escaping (inout [Float]) -> Void)
    {
        super.init(name: name, description: description)
        
        self.change = change_func
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        #if os(macOS)
        self.change = external_change_func
        #endif
    }
    
    open override var extension_name: String { "changer" }
    
    // MARK: - Components
    ///
    @Published public var changer_function_code = String() //JS
    
    // MARK: - Import functions
    open override var package_url: URL
    {
        do
        {
            var is_stale = false
            var local_url = try URL(resolvingBookmarkData: WorkspaceObject.modules_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return local_url
            }
            
            local_url = local_url.appendingPathComponent("\(name).changer")
            
            return local_url
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    // MARK: - Designer functions
    // ...
    
    // MARK: - Components
    /// A main external code file name
    //public var code_file_name: String { "Count" }
    
    /**
     Performs register conversion within a class instance.
     - Parameters:
        - registers: A changeable registers data.
     */
    public var change: (inout [Float]) throws -> Void = { _ in }
    //public var change: (inout [Float]) -> Void = { _ in }
    
    #if os(macOS)
    override open var program_components_paths: [(file: String, socket: String)]
    {
        return [
            (
                file: "/Code/Change",
                socket: "/tmp/\(name.code_correct_format)_change_socket"
            )
        ]
    }
    
    /**
     Performs register data change within an external script.
     - Parameters:
        - registers: A changeable registers data.
     
     The conversion occurs by executing code in an external swift file.
     */
    private func external_change_func(registers: inout [Float]) -> Void
    {
        guard let output: String = send_via_unix_socket(at: "/tmp/\(name)_change_socket", with: ["change"] + registers.map { String($0) })
        else
        {
            return
        }
        
        registers = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").compactMap { Float($0) }
    }
    #endif
    
    // MARK: - Codable handling
    enum CodingKeys: String, CodingKey
    {
        case changer_function_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.changer_function_code = try container.decode(String.self, forKey: .changer_function_code)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(changer_function_code, forKey: .changer_function_code)
        
        try super.encode(to: encoder)
    }
}
