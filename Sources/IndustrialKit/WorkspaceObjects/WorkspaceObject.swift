//
//  WorkspaceObject.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 29.10.2022.
//

import Foundation
import SceneKit
import SwiftUI

/**
 A base class of industrial production object.
 
 Industrial production objects are represented by equipment that provide technological operations performing.
 */
open class WorkspaceObject: Identifiable, Equatable, Hashable, ObservableObject
{
    public static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool //Identity condition by names
    {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var id = UUID() //Object identifier
    
    ///Object name in workspace
    public var name: String?
    
    public init()
    {
        self.name = "None"
    }
    
    public init(name: String) //Init object by name. Used for mismatch.
    {
        self.name = name
    }
    
    //MARK: - Object in workspace handling
    ///In workspace placement state.
    public var is_placed = false
    
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
                    self.node = try SCNScene(url: URL(string: url.absoluteString + scene_address)!).rootNode.childNode(withName: scene_node_name ?? "", recursively: false)
                }
                catch
                {
                    print(error.localizedDescription)
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
            print(error.localizedDescription)
            node_by_internal()
        }
    }
    
    private func node_by_internal()
    {
        node = SCNNode()
        print(scene_internal_folder_address! + "/" + scene_address)
        
        if scene_internal_folder_address != nil && (scene_node_name != nil || scene_node_name != "")
        {
            //Get model scene from application resources
            node = SCNScene(named: scene_internal_folder_address! + "/" + scene_address)!.rootNode.childNode(withName: scene_node_name!, recursively: false)!
        }
        else
        {
            //Get node by description
            node_by_description()
        }
    }
    
    ///Builds model by description without external scene.
    open func node_by_description()
    {
        no_model_node()
    }
    
    ///Builds a filler node for object without model description.
    public func no_model_node()
    {
        //Build filler model node
        node?.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor.gray
        #else
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        #endif
        
        node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        node?.name = scene_node_name
    }
    
    //MARK: - UI functions
    ///Universal data storage for NSImage or UIImage.
    public var image_data = Data()
    
    #if os(macOS)
    ///Workspace object preview image.
    public var image: NSImage
    {
        get
        {
            return NSImage(data: image_data) ?? NSImage() //Retrun NSImage from image data
        }
        set
        {
            image_data = newValue.tiffRepresentation ?? Data() //Convert NSImage to image data
        }
    }
    
    ///Returns info for object card view (with NSImage).
    public var card_info: (title: String, subtitle: String, color: Color, image: NSImage)
    {
        return("Title", "Subtitle", Color.clear, NSImage())
    }
    #else
    ///Workspace object preview image.
    public var image: UIImage
    {
        get
        {
            return UIImage(data: image_data) ?? UIImage() //Retrun UIImage from image data
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
    #endif
}
