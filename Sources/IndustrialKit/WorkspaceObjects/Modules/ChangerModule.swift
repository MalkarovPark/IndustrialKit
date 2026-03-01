//
//  ChangerModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import JavaScriptCore

open class ChangerModule: IndustrialModule
{
    // MARK: - Module init functions for design
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    // MARK: Module init functions for in-app mounting
    /// Internal module init.
    public init(name: String = String(), description: String = String(), change_func: @escaping (inout [Float]) throws -> Void)
    {
        super.init(name: name, description: description)
        
        //self.change = change_func
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        //self.change = external_change_func
    }
    
    open override var extension_name: String { "changer" }
    
    // MARK: - Components
    /**
     JavaScript code used to transform register values inside the Changer component.
     
     The script must operate on the `registers` array (Float[]) and return the modified array as the last expression.
     */
    @Published public var changer_function_code = String() // JS
    
    /**
     Performs register conversion within a class instance.
     
     - Parameters:
     - registers: A mutable registers data array.
     
     - Throws:
     NSError(domain: "Performing Error", code: 1)
     if JavaScript execution fails or returns invalid data.
     */
    public func change(_ registers: inout [Float]) throws
    {
        let context = JSContext()!
        
        var jsErrorMessage: String?
        
        context.exceptionHandler =
        { _, exception in
            jsErrorMessage = exception?.toString()
        }
        
        // Convert Swift [Float] -> JS Array
        let jsRegisters = JSValue(object: registers.map { Double($0) }, in: context)
        context.setObject(jsRegisters, forKeyedSubscript: "registers" as NSString)
        
        guard let result = context.evaluateScript(changer_function_code)
        else
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: jsErrorMessage ?? "Unknown JavaScript error"
                ]
            )
        }
        
        if let error = jsErrorMessage
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: error
                ]
            )
        }
        
        guard result.isArray,
              let newValues = result.toArray() as? [Double]
        else
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "JavaScript must return an array of numbers."
                ]
            )
        }
        
        registers = newValues.map { Float($0) }
    }
    
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
