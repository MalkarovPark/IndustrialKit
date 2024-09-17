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
    //MARK: - Import functions
    override open func external_import()
    {
        self.node = external_node
    }
    
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
}
