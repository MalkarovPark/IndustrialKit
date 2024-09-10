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
open class WorkspaceObject: Identifiable, Equatable, Hashable, ObservableObject //, NSCopying
{
    public static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool //Identity condition by names
    {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    ///Object identifier.
    public var id = UUID()
    
    ///Object name in workspace.
    public var name = String()
    
    ///A name of module to describe scene, controller and connector.
    public var module_name = ""
    
    ///Object init function.
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
    
    //MARK: - Object in workspace handling
    ///In workspace placement state.
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
    
    ///Additional operations after remowing an object from the workspace.
    open func on_remove()
    {
        
    }
    
    ///Object location components – *x*, *y*, *z*.
    public var location = [Float](repeating: 0, count: 3)
    
    ///Object rotation components – *r*, *p*, *w*.
    public var rotation = [Float](repeating: 0, count: 3)
    
    //MARK: - Visual functions
    ///Scene file address.
    public var scene_address = ""
    
    ///Connected object scene node.
    public var node: SCNNode?
    
    ///Name of node for connect to instance node variable.
    open var scene_node_name: String? { nil }
    
    ///Addres of internal folder with workspace objects scenes.
    open var scene_internal_folder_address: String? { nil }
    
    ///Folder access bookmark.
    public static var folder_bookmark: Data?
    
    ///Gets model node in scene imported from file.
    public func get_node_from_scene()
    {
        do
        {
            //File access
            var is_stale = false
            let url = try URL(resolvingBookmarkData: WorkspaceObject.folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return
            }
            
            if scene_address != "" //If scene address not empty, get node from it
            {
                do
                {
                    self.node = try SCNScene(url: URL(string: url.absoluteString + scene_address)!).rootNode.childNode(withName: scene_node_name ?? "", recursively: false)?.clone()
                }
                catch
                {
                    //print(error.localizedDescription)
                    node_by_internal() //If node could not imported, create node model by description
                }
            }
            else
            {
                node_by_internal()
            }
        }
        catch
        {
            //print(error.localizedDescription)
            node_by_internal()
        }
    }
    
    ///Set workspace object node by internal resource.
    private func node_by_internal()
    {
        node = SCNNode()
        
        if scene_internal_folder_address != nil && scene_node_name != nil
        {
            //Get model scene from application resources
            guard let new_scene = SCNScene(named: scene_internal_folder_address! + (scene_internal_folder_address != "" ? "/" : "") + scene_address)
            else
            {
                node_by_description()
                return
            }
            
            node = new_scene.rootNode.childNode(withName: scene_node_name!, recursively: false)!
        }
        else
        {
            //Get node by description
            node_by_description()
        }
    }
    
    /**
     Builds model node by description without external scene.
     
     Name of the scene corresponds to name of the module.
     */
    open func node_by_description()
    {
        no_model_node()
    }
    
    ///Builds a filler node for object without model description.
    public func no_model_node()
    {
        //Build filler model node
        node?.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        
        node?.name = scene_node_name
    }
    
    //MARK: - UI functions
    ///Universal data storage for NSImage or UIImage.
    public var image_data: Data? = nil
    
    ///Workspace object preview image.
    public var image: UIImage
    {
        get
        {
            return UIImage(data: image_data ?? Data()) ?? UIImage() //Retrun UIImage from image data
        }
        set
        {
            image_data = newValue.pngData() ?? Data() //Convert UIImage to image data
        }
    }
    
    ///Returns info for object card view (with UIImage).
    public var card_info: (title: String, subtitle: String, color: Color, image: UIImage)
    {
        return("Title", "Subtitle", Color.clear, UIImage())
    }
    
    ///Clears preview image in object.
    public func clear_preview()
    {
        image_data = nil
    }
}
