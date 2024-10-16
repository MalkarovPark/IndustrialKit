//
//  ChangerModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation

open class ChangerModule: IndustrialModule
{
    //MARK: - Init functions
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    //MARK: Module init for in-app mounting
    ///Internal module init.
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
    
    //MARK: - Designer functions
    open override var default_code_items: [CodeItem]
    {
        return [CodeItem(name: "Change")]
    }
    
    //MARK: - Components
    ///A main external code file name
    public var code_file_name: String { "Count" }
    
    /**
     Performs register conversion within a class instance.
     - Parameters:
        - registers: A changeable registers data.
     */
    public var change: (inout [Float]) -> Void = { _ in }
    
    #if os(macOS)
    /**
     Performs register data change within an external script.
     - Parameters:
        - registers: A changeable registers data.
     
     The conversion occurs by executing code in an external swift file.
     */
    private func external_change_func(registers: inout [Float]) -> Void
    {
        guard let output: String = perform_code(at: URL(string: package_url.path() + "/Code/Changer")!, with: registers.map { String($0) })
        else
        {
            return
        }
        
        registers = output.split(separator: " ").compactMap { Float($0) }
    }
    #endif
    
    //MARK: - Codable handling
    required public init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}
