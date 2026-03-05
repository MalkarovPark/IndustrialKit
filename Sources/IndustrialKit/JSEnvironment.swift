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
    
    public var js_code: String
    {
        didSet
        {
            build_context()
        }
    }
    
    // MARK: - Context
    private let vm = JSVirtualMachine()
    private var context: JSContext?
    
    private var js_error_message: String?
    
    // function cache
    private var functions: [String: JSValue] = [:]
    
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
    
    private func js_function(named name: String) -> JSValue? // Function lookup
    {
        if let cached = functions[name]
        {
            return cached
        }
        
        guard let context else
        {
            return nil
        }
        
        guard let fn = context.objectForKeyedSubscript(name),
              !fn.isUndefined
        else
        {
            return nil
        }
        
        functions[name] = fn
        
        return fn
    }
    
    // MARK: - Call JS Function
    public func call_js_func(name: String) throws -> String
    {
        js_error_message = nil
        
        guard let fn = js_function(named: name)
        else
        {
            throw NSError(
                domain: "Performing Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "JavaScript function '\(name)' not found"
                ]
            )
        }
        
        guard let result = fn.call(withArguments: [])
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
        
        return result.toString()
    }
    
    public func reset_context()
    {
        build_context()
    }
}
