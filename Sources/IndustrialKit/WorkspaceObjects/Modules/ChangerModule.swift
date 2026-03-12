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
    /// Module init with internal Swift function.
    public init(
        name: String = String(),
        description: String = String(),
        
        changer_function: @escaping (inout [Float]) throws -> Void
    )
    {
        super.init(name: name, description: description)
        
        self.change = changer_function
    }
    
    /// Module init with external JS function.
    public init(
        name: String = String(),
        description: String = String(),
        
        changer_function_code: String
    )
    {
        super.init(name: name, description: description)
        
        self.change = js_change
        self.changer_function_code = changer_function_code
    }
    
    /// Module init with external JS function (context).
    public override init(
        name: String = String(),
        description: String = String()
    )
    {
        super.init(name: name, description: description)
        
        self.change = js_change
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.change = js_change
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
    public var change: (_ registers: inout [Float]) throws -> Void = { _ in }
    
    public func js_change(_ registers: inout [Float]) throws
    {
        let context = JSContext()!
        
        var js_error_message: String?
        
        context.exceptionHandler =
        { _, exception in
            js_error_message = exception?.toString()
        }
        
        // Convert Swift [Float] to JS Array
        let js_registers = JSValue(object: registers.map { Double($0) }, in: context)
        context.setObject(js_registers, forKeyedSubscript: "registers" as NSString)
        
        guard let result = context.evaluateScript(changer_function_code)
        else
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: js_error_message ?? "Unknown JavaScript error"
                ]
            )
        }
        
        if let error = js_error_message
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
              let new_values = result.toArray() as? [Double]
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
        
        registers = new_values.map { Float($0) }
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
