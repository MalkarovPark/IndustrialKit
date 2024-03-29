//
//  WorkspaceObjectModule.swift
//  IndustrialKit
//
//  Created by Artem on 28.03.2024.
//

import Foundation
import SceneKit

open class WorkspaceObjectModule: Codable
{
    //MARK: Description
    public var name: String //Module name
    public var description: String //Module description
    
    //MARK: File handling
    public static var folder_bookmark: Data? //Folder bookmark to resources access
    public var file_name: String //File name for access internals (on file open – update name?)
    
    //Folders
    private static let components_address = "Components"
    private static let resources_address = "Resources"
    private static let scripts_address = "Scripts"
    
    open var extension_name: String { "object" } //Object package extension name
    
    //MARK: Data output
    public var scene: SCNScene
    {
        return SCNScene()
    }
    
    open var scene_name: String? { nil }
    open var node_name: String? { nil }
    
    ///Gets model node from scene in package file.
    public var node: SCNNode
    {
        do
        {
            //File access
            var is_stale = false
            let url = try URL(resolvingBookmarkData: WorkspaceObjectModule.folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale && scene_name != nil && node_name != nil else
            {
                return default_node
            }
            
            let scene_address = "\(url.absoluteString)\(file_name).\(extension_name)/\(WorkspaceObjectModule.components_address)/\(WorkspaceObjectModule.resources_address)/\(scene_name!).scn"
            
            do
            {
                let node = try SCNScene(url: URL(string: scene_address)!).rootNode.childNode(withName: node_name ?? "", recursively: false)?.clone() ?? default_node
                
                return node
            }
            catch
            {
                print(error.localizedDescription)
                return default_node //If node could not imported, create node model by description
            }
        }
        catch
        {
            print(error.localizedDescription)
            return default_node
        }
    }
    
    ///Set default node for workspace object.
    open var default_node: SCNNode { SCNNode() }
}
