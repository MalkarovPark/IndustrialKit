//
//  JSEnvironment.swift
//  IndustrialKit
//
//  Created by Artem on 05.03.2026.
//

import Foundation
import JavaScriptCore

/// A lightweight JavaScript execution environment.
///
/// `JSEnvironment` provides an isolated runtime for evaluating JavaScript code
/// and invoking functions from Swift.
///
/// The environment encapsulates:
/// - A dedicated JavaScript virtual machine
/// - A runtime context (`JSContext`)
/// - A function cache for optimized repeated calls
///
/// JavaScript code is evaluated upon initialization or when ``js_code`` changes,
/// rebuilding the execution context and resetting all runtime state.
///
/// This abstraction enables integration of dynamic scripting logic into
/// production workflows, simulation pipelines, or device-level processing.
/// 
public class JSEnvironment
{
    // MARK: - Initializer
    /// Creates a JavaScript execution environment.
    ///
    /// The provided JavaScript code is evaluated immediately, initializing
    /// the runtime context and preparing callable functions.
    ///
    /// - Parameter js_code: A JavaScript source code string.
    public init(js_code: String = String())
    {
        self.js_code = js_code
        
        build_context()
    }
    
    /// JavaScript code evaluated within the environment.
    ///
    /// Updating this value rebuilds the underlying context,
    /// clearing all previously defined variables and cached functions.
    public var js_code: String
    {
        didSet
        {
            build_context()
        }
    }
    
    /// The underlying JavaScript virtual machine.
    ///
    /// The virtual machine isolates execution and manages memory
    /// for the associated JavaScript context.
    private let vm = JSVirtualMachine()
    
    /// The JavaScript execution context.
    ///
    /// The context stores runtime state, including variables,
    /// functions, and evaluation results.
    private var context: JSContext?
    
    /// The last error message produced during JavaScript evaluation.
    ///
    /// This value is updated by the exception handler and used
    /// for error propagation to Swift.
    private var js_error_message: String?
    
    /// A cache of resolved JavaScript functions.
    ///
    /// Cached functions improve performance by avoiding repeated
    /// lookups in the JavaScript context.
    private var functions: [String: JSValue] = [:]
    
    // MARK: - Context Management
    /// Builds or rebuilds the JavaScript execution context.
    ///
    /// The method:
    /// - Clears previous error state
    /// - Resets the function cache
    /// - Creates a new `JSContext`
    /// - Installs an exception handler
    /// - Evaluates the current ``js_code``
    ///
    /// This operation fully resets the runtime environment.
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
    
    /// Retrieves a JavaScript function by name.
    ///
    /// The method first checks the internal cache, then queries
    /// the JavaScript context if needed.
    ///
    /// - Parameter name: A function identifier.
    /// - Returns: A `JSValue` representing the function, or `nil` if not found.
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
    
    // MARK: - Function Invocation
    /// Calls a JavaScript function without arguments.
    ///
    /// - Parameter name: A function identifier.
    /// - Returns: A string representation of the result.
    /// - Throws: An error if the function is not found or execution fails.
    public func call_js_func(name: String) throws -> String
    {
        return try call_js_func(name: name, args: [])
    }
    
    /// Calls a JavaScript function with arguments.
    ///
    /// The method resolves the function, executes it with provided arguments,
    /// and converts the result to a string.
    ///
    /// Errors occurring during execution are captured via the exception handler
    /// and propagated as Swift errors.
    ///
    /// - Parameters:
    ///   - name: A function identifier.
    ///   - args: A list of arguments passed to the function.
    /// - Returns: A string representation of the result.
    /// - Throws: An error if the function is missing or execution fails.
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
    
    /// Resets the JavaScript execution context.
    ///
    /// This method rebuilds the context, clearing all variables,
    /// cached functions, and previous execution state.
    public func reset_context()
    {
        build_context()
    }
}
