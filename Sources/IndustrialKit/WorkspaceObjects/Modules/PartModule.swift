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
    
    //MARK: Module init for mount in app
    ///Internal init.
    public init(name: String = String(), description: String = String(), node: SCNNode)
    {
        super.init(name: name, description: description, is_internal: true)
        
        self.node = node
    }
    
    public override init(external_name: String)
    {
        super.init(external_name: external_name)
        
        self.node = external_node
    }
    
    //MARK: - Import functions
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
    }
}
