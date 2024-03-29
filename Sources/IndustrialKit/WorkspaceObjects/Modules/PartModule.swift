//
//  PartModule.swift
//  IndustrialKit
//
//  Created by Artem on 29.03.2024.
//

import Foundation
import SceneKit

class PartModule: WorkspaceObjectModule
{
    public override var extension_name: String { "part" }
    
    public override var default_node: SCNNode
    {
        //Build filler model node
        let node = SCNNode()
        
        node.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        node.geometry?.firstMaterial?.lightingModel = .physicallyBased
        
        node.name = node_name
        
        return node
    }
}
