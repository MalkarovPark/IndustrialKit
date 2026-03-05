//
//  JSEnvironment.swift
//  IndustrialKit
//
//  Created by Artem on 05.03.2026.
//

import Foundation
import JavaScriptCore

public class JSEnvironment
{
    // MARK: - Init
    public init(js_code: String = String())
    {
        self.js_code = js_code
        
        build_context()
    }
    
    /// JavaScript code to be executed in this environment.
    public var js_code: String
    {
        didSet
        {
            build_context()
        }
    }
    
    /// Underlying JS virtual machine.
    private let vm = JSVirtualMachine()
    
    /// JSContext storing the runtime state.
    private var context: JSContext?
    
    /// Last JS error message.
    private var js_error_message: String?
    
    /// Cache of JS functions for faster repeated calls.
    private var functions: [String: JSValue] = [:]
    
    /// Build or rebuild JS context and function cache.
    private func build_context()
    {
        js_error_message = nil
        functions.removeAll()
        
        context = JSContext(virtualMachine: vm)
        
        context?.exceptionHandler =
        { [weak self] _, exception in
            self?.js_error_message = exception?.toString()
        }
        
        context?.evaluateScript(js_code)
    }
    
    /// Retrieve a JS function by name, using cache.
    private func js_function(named name: String) -> JSValue?
    {
        if let cached = functions[name] {
            return cached
        }
        
        guard let context,
              let function_name = context.objectForKeyedSubscript(name),
              !function_name.isUndefined
        else { return nil }
        
        functions[name] = function_name
        
        return function_name
    }
    
    // MARK: - Call JS Function
    /// Call a JS function with no arguments.
    public func call_js_func(name: String) throws -> String
    {
        return try call_js_func(name: name, args: [])
    }
    
    /// Call a JS function with arguments.
    public func call_js_func(name: String, args: [Any]) throws -> String
    {
        js_error_message = nil
        
        guard let fn = js_function(named: name) else
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "JavaScript function '\(name)' not found"
                ]
            )
        }
        
        guard let result = fn.call(withArguments: args) else
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
        
        return result.toString()
    }
    
    /// Reset JS context, clearing all variables and function cache.
    public func reset_context()
    {
        build_context()
    }
}
