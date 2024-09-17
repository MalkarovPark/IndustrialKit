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
    ///Internal init.
    public init(name: String = String(), description: String = String(), node: SCNNode)
    {
        super.init(name: name, description: description, is_internal: true)
        
        self.node = node
    }
    
    ///External init.
    public init(name: String = String(), package_file_name: String = String())
    {
        super.init(name: name, package_file_name: package_file_name, is_internal: false)
        
        external_import()
    }
    
    //MARK: - Import functions
    override open func external_import()
    {
        self.node = external_node
    }
    
    override open var external_node: SCNNode
    {
        return SCNNode()
    }
    
    //MARK: - Codable handling
    public required init(from decoder: any Decoder) throws
    {
        try super.init(from: decoder)
        
        external_import()
    }
}
