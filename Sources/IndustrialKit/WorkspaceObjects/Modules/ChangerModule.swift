//
//  ChangerModule.swift
//  Industrial Builder
//
//  Created by Artem on 11.04.2024.
//

import Foundation

public class ChangerModule: IndustrialModule
{
    ///A main external code file name
    public var code_file_name: String { "Count" }
    
    /**
     Performs register conversion within a class instance.
     - Parameters:
        - registers: A changeable registers data.
     */
    public func change(registers: inout [Float])
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
    }
    
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
    private func external_change(registers: [Float]) -> [Float]
    {
        guard let internal_url = internal_url
        else
        {
            return [Float]()
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["swift", "\(internal_url)/Components/Code/\(package_file_name)/\(code_file_name).swift"] + registers.map { String($0) }
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        //Converting the output back to a Float array
        let new_registers = output?.split(separator: " ").compactMap { Float($0) }
        return new_registers ?? []
    }
    #endif
    
    //MARK: - Work with file system
    public init(name: String = String(), description: String = String(), package_file_name: String = String(), is_internal_change: Bool = Bool(), internal_code: String = String())
    {
        super.init(name: name, description: description, package_file_name: package_file_name)
        code_items = [CodeItem(name: "Change")]
    }
    
    //MARK: Codable handling
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
