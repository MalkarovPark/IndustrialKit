//
//  WorkspaceObject.swift
//  IndustrialKit
//
//  Created by Artem on 29.10.2022.
//

import Foundation
import SceneKit
import SwiftUI

/**
 A base class of industrial production object.
 
 Industrial production objects are represented by equipment that provide technological operations performing.
 */
open class WorkspaceObject: Identifiable, Equatable, Hashable, ObservableObject, Codable // , NSCopying
{
    public static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool // Identity condition by names
    {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    /// Object identifier.
    public var id = UUID()
    
    /// Object name in workspace.
    public var name = String()
    
    /// A name of module to describe scene, controller and connector.
    public var module_name = ""
    
    /// A module access type identifier – external or internal.
    public var is_internal_module = true
    
    /// Object init function.
    public init()
    {
        
    }
    
    /**
     Inits object by name.
     
     Used for object mismatch.
     */
    public init(name: String)
    {
        self.name = name
    }
    
    /// Inits object by name and module name of installed module.
    public init(name: String, module_name: String, is_internal: Bool = true)
    {
        self.name = name
        self.is_internal_module = is_internal
        module_import_by_name(module_name, is_internal: is_internal)
    }
    
    // MARK: - Module handling
    /// Modules folder access bookmark.
    public static var modules_folder_bookmark: Data?
    
    /**
     Imports module by name.
     - Parameters:
        - name: An installed module name.
     */
    open func module_import_by_name(_ name: String, is_internal: Bool = true)
    {
        
    }
    
    // MARK: - Object in workspace handling
    /// In workspace placement state.
    @Published public var is_placed = false
    {
        didSet
        {
            if !is_placed
            {
                location = [0, 0, 0]
                rotation = [0, 0, 0]
                on_remove()
            }
        }
    }
    
    /// Additional operations after remowing an object from the workspace.
    open func on_remove()
    {
        
    }
    
    /// Object location components – *x*, *y*, *z*.
    public var location = [Float](repeating: 0, count: 3)
    
    /// Object rotation components – *r*, *p*, *w*.
    public var rotation = [Float](repeating: 0, count: 3)
    
    // MARK: - Update functions
    /// Flag indicating whether the update loop is active.
    private var updated = false
    
    /// The task responsible for executing the update loop.
    private var update_task: Task<Void, Never>?
    
    /// The interval between updates in nanoseconds.
    public static var update_interval: UInt64 = 1_000_000_0
    
    /**
     Starts the update loop.
     
     This function sets the `updated` flag to `true` and initiates a new task that repeatedly calls the `update()` function on the main thread.  The loop runs as long as the `updated` flag remains `true`.  A sleep duration of approximately 1 millisecond is introduced between each update cycle. The task can be cancelled by calling `disable_update()`.
     */
    public func perform_update()
    {
        updated = true
        
        update_task = Task
        {
            while updated
            {
                try? await Task.sleep(nanoseconds: WorkspaceObject.update_interval)
                await MainActor.run
                {
                    self.update()
                }
                
                if(update_task == nil)
                {
                    return
                }
            }
        }
    }
    
    /**
     Stops the update loop.
     
     This function sets the `updated` flag to `false`, cancels the `update_task`, and sets it to `nil`.  This effectively terminates the update loop initiated by `perform_update()`.
     */
    public func disable_update()
    {
        updated = false
        update_task?.cancel()
        update_task = nil
    }
    
    /**
     Called repeatedly within the update loop to perform updates.
     
     This function is called on the main thread by the `perform_update()` function as long as the `updated` flag is `true`. Subclasses should override this method to implement their specific update logic.
     
     > This function is called frequently, so it's crucial to keep its execution time as short as possible to avoid performance issues.
     */
    open func update()
    {
        
    }
    
    // MARK: - Visual functions
    /// Scene file address.
    public var scene_address = ""
    
    /// Connected object scene node.
    public var node: SCNNode?
    
    /// Name of node for connect to instance node variable.
    open var scene_node_name: String? { nil }
    
    /// Addres of internal folder with workspace objects scenes.
    open var scene_internal_folder_address: String? { nil }
    
    /// Folder access bookmark.
    // public static var folder_bookmark: Data?
    
    // MARK: - UI functions
    /*///Universal data storage for NSImage or UIImage.
    public var image_data: Data? = nil*/
    
    /*///Workspace object preview image.
    public var image: UIImage
    {
        get
        {
            return UIImage(data: image_data ?? Data()) ?? UIImage() // Retrun UIImage from image data
        }
        set
        {
            image_data = newValue.pngData() ?? Data() // Convert UIImage to image data
        }
    }*/
    
    /// Returns info for object card view (with UIImage).
    open var card_info: (title: String, subtitle: String, color: Color, image: UIImage, node: SCNNode)
    {
        return("Title", "Subtitle", Color.clear, UIImage(), SCNNode())
    }
    
    /// Clears preview image in object.
    /*public func clear_preview()
    {
        image_data = nil
    }*/
    
    // MARK: - Work with file system
    private enum CodingKeys: String, CodingKey
    {
        case name
        
        case module_name
        case is_internal_module
        
        case location
        case rotation
        case is_placed
    }
    
    public required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        
        self.module_name = try container.decode(String.self, forKey: .module_name)
        self.is_internal_module = try container.decodeIfPresent(Bool.self, forKey: .is_internal_module) ?? true // self.is_internal_module = try container.decode(Bool.self, forKey: .is_internal_module)
        
        self.location = try container.decode([Float].self, forKey: .location)
        self.rotation = try container.decode([Float].self, forKey: .rotation)
        self.is_placed = try container.decode(Bool.self, forKey: .is_placed)
        
        // color_to_model()
        module_import_by_name(module_name, is_internal: self.is_internal_module)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(module_name, forKey: .module_name)
        try container.encode(is_internal_module, forKey: .is_internal_module)
        
        try container.encode(location, forKey: .location)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(is_placed, forKey: .is_placed)
    }
}
