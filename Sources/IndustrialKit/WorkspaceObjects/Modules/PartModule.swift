//
//  PartModule.swift
//  IndustrialKit
//
//  Created by Artem on 11.04.2024.
//

import Foundation
import SceneKit

open class PartModule: IndustrialModule
{
    //MARK: - Init functions
    public override init(new_name: String = String(), description: String = String())
    {
        super.init(new_name: new_name, description: description)
    }
    
    //MARK: Module init for in-app mounting
    ///Internal init.
    public init(name: String = String(), description: String = String(), node: SCNNode)
    {
        super.init(name: name, description: description)
        
        self.node = node
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        node = external_node
    }
    
    //MARK: - Import functions
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
            
            local_url = local_url.appendingPathComponent("\(name).part")
            
            return local_url
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return URL(filePath: "")
    }
    
    public var external_module_info: PartModule?
    {
        do
        {
            let info_url = package_url.appendingPathComponent("/Info")
            
            if FileManager.default.fileExists(atPath: info_url.path)
            {
                return try JSONDecoder().decode(PartModule.self, from: try Data(contentsOf: info_url))
            }
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    open override var external_node: SCNNode
    {
        if let main_scene_name = external_module_info?.main_scene_name
        {
            do
            {
                let scene_url = package_url.appendingPathComponent("/Resources.scnassets/\(main_scene_name)")
                
                if FileManager.default.fileExists(atPath: scene_url.path)
                {
                    let scene_data = try Data(contentsOf: scene_url)
                    
                    if let scene_source = SCNSceneSource(data: scene_data, options: nil)
                    {
                        if let external_scene = scene_source.scene(options: nil)
                        {
                            print("Imported – \(external_scene)")
                            return external_scene.rootNode.clone()
                            //return external_scene.rootNode.childNode(withName: "part", recursively: true)!.clone()
                        }
                    }
                }
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        
        return SCNNode()
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}
