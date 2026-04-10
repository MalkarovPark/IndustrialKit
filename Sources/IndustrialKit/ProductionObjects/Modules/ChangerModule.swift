//
//  ChangerModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import JavaScriptCore

/// A module that performs transformation of register data within a production system.
///
/// `ChangerModule` extends ``IndustrialModule`` by providing a mechanism
/// for dynamic modification of numeric register arrays.
///
/// The module defines a transformation function that can be implemented:
/// - As a native Swift closure
/// - As a JavaScript function executed at runtime
///
/// This abstraction enables flexible data processing pipelines,
/// including signal transformation, calibration, normalization,
/// and custom runtime logic.
///
/// Changer modules are typically used as intermediate processing units
/// between devices, programs, or control layers.
open class ChangerModule: IndustrialModule
{
    // MARK: - MARK: - Initialization
    // MARK: Module init functions for design
    /// Creates a changer module using a default JavaScript-based transformation.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description of the module.
    public override init(
        name: String = String(),
        description: String = String()
    )
    {
        super.init(name: name, description: description)
        
        self.change = js_change
    }
    
    /*public override init(
        new_name: String = String(),
        description: String = String()
    )
    {
        super.init(new_name: new_name, description: description)
    }*/
    
    // MARK: Module init functions for in-app mounting
    /// Creates a changer module with a native Swift transformation function.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    ///   - changer_function: A closure that modifies register values.
    public init(
        name: String = String(),
        description: String = String(),
        
        changer_function: @escaping (inout [Float]) throws -> Void
    )
    {
        super.init(name: name, description: description)
        
        self.change = changer_function
    }
    
    /// Creates a changer module using JavaScript transformation code.
    ///
    /// The provided code is executed at runtime to transform register values.
    ///
    /// - Parameters:
    ///   - name: A module identifier.
    ///   - description: A textual description.
    ///   - changer_function_code: A JavaScript source code string.
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
    
    /// Creates a changer module from an external package.
    ///
    /// The module uses JavaScript-based transformation by default.
    ///
    /// - Parameter external_name: A module identifier.
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.change = js_change
    }
    
    /// A file extension representing the changer module package format.
    open override var file_extension_name: String { "changer" }
    
    // MARK: - Components
    /// A transformation function that modifies register values.
    ///
    /// The function receives a mutable array of registers and applies
    /// in-place modifications. It may throw an error if transformation fails.
    ///
    /// This function can be implemented either as a native Swift closure
    /// or as a wrapper around JavaScript execution.
    public var change: (_ registers: inout [Float]) throws -> Void = { _ in }
    
    /// A JavaScript source code used for register transformation.
    ///
    /// The script operates on a `registers` array and must return
    /// a modified array of numeric values.
    ///
    /// The result is converted back into Swift `[Float]` representation.
    @Published public var changer_function_code = String() // JS
    
    /// Executes the JavaScript transformation on register values.
    ///
    /// The method evaluates ``changer_function_code`` inside a JavaScript context,
    /// passing the current register array and expecting a transformed array in return.
    ///
    /// - Parameter registers: A mutable array of register values.
    /// - Throws: An error if script execution fails or returns invalid data.
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
            var local_url = try URL(resolvingBookmarkData: ProductionObject.modules_folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return local_url
            }
            
            local_url = local_url.appendingPathComponent("\(name).changer")
            
            return local_url
        }
        catch
        {
            //print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    // MARK: - File Data
    enum CodingKeys: String, CodingKey
    {
        case changer_function_code
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.changer_function_code = try container.decode(String.self, forKey: .changer_function_code)
        
        try super.init(from: decoder)
        
        self.change = js_change
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(changer_function_code, forKey: .changer_function_code)
        
        try super.encode(to: encoder)
    }
}
