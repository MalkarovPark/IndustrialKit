//
//  ChangerModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

open class ChangerModule: IndustrialModule
{
    // MARK: - Init functions
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init for in-app mounting
    /// Internal module init.
    public init(name: String = String(), description: String = String(), change_func: @escaping (inout [Float]) -> Void)
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
    open override var default_code_items: [String: String]
    {
        return ["Change": String()]
    }
    
    // MARK: - Components
    /// A main external code file name
    //public var code_file_name: String { "Count" }
    
    /**
     Performs register conversion within a class instance.
     - Parameters:
        - registers: A changeable registers data.
     */
    public var change: (inout [Float]) -> Void = { _ in }
    
    #if os(macOS)
    override open func start_program_components()
    {
        perform_terminal_app_sync(at: self.package_url.appendingPathComponent("/Code/Change"), with: [" > /dev/null 2>&1 &"])
    }
    
    override open func stop_program_components()
    {
        send_via_unix_socket(at: "/tmp/\(name)_change_socket", command: "stop")
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
    required public init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}
