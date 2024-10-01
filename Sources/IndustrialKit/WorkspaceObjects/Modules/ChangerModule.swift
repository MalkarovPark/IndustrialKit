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
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal_change: Bool = Bool())
    {
        super.init(name: name, description: description)
        code_items = [CodeItem(name: "Change")]
    }
    
    ///Internal Init
    public init(name: String = String(), description: String = String(), change_func: @escaping (inout [Float]) -> Void)
    {
        super.init(name: name, description: description, is_internal: true)
        
        self.change = change_func
    }
    
    ///External Init
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.change = external_change_func
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
    
    /*public func change(registers: inout [Float])
    {
        if is_internal
        {
            registers = internal_change(registers: registers)
        }
        else
        {
            #if os(macOS)
            registers = external_change(registers: registers)
            #endif
        }
    }*/
    
    /**
     Performs register conversion within a class instance.
     - Parameters:
        - registers: A changeable registers data.
     
     The contents of this function are specified in the listing and compiled in the application.
     */
    private func internal_change(registers: [Float]) -> [Float]
    {
        /*@START_MENU_TOKEN@*/return [Float]()/*@END_MENU_TOKEN@*/
    }
    
    #if os(macOS)
    /**
     Performs register conversion within an external script.
     - Parameters:
        - registers: A changeable registers data.
     
     The conversion occurs by executing code in an external swift file.
     */
    private func external_change_func(registers: inout [Float]) -> Void
    {
        guard let internal_url = internal_url
        else
        {
            registers = [Float]()
            return
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["swift", "\(internal_url)/Components/Code/\(name)/\(code_file_name).swift"] + registers.map { String($0) }
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        //Converting the output back to a Float array
        let new_registers = output?.split(separator: " ").compactMap { Float($0) }
        registers = new_registers ?? [Float]()
    }
    #endif
    
    //MARK: - Codable handling
    required public init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}

/*@START_MENU_TOKEN@*//*@PLACEHOLDER=Additive Code@*//*@END_MENU_TOKEN@*/

//External code file example
/*
import Foundation

if CommandLine.arguments.count > 1
{
    let inputNumbers = CommandLine.arguments.dropFirst().compactMap { Float($0) }
    let transformedNumbers = inputNumbers.map { $0 * 2 }
    print(transformedNumbers.map { String($0) }.joined(separator: " "))
}
else
{
    print("Ошибка: Необходимо передать массив чисел в качестве аргументов.")
}
*/
