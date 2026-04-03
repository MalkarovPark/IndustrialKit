//
//  PendantController.swift
//  IndustrialKit
//
//  Created by Artem on 10.02.2024.
//

import Foundation
import IndustrialKit

/**
 A class that provides integration between applications and the Spatial Pendant.
 */
@MainActor public class PendantController: ObservableObject
{
    public init()
    {
        
    }
    
    // MARK: - Workspace management
    @Published public var workspace = Workspace()
    
    public init(workspace: Workspace)
    {
        self.workspace = workspace
    }
    
    // MARK: - Windows management
    private var open = {}
    private var dismiss = {}
    
    @Published public var is_opened = false
    {
        didSet
        {
            if is_opened
            {
                // Open s-pendant window
                open()
            }
            else
            {
                // Dismisses s-pendant window
                dismiss()
            }
        }
    }
    
    /**
     Resets the window management state on s-pendant disappear.
     
     > Set it to **onDisappear** method of the s-pendant view.
     */
    public func on_dismiss()
    {
        is_opened = false
    }
    
    /**
     Sets the s-pendant window control functions.
     
     - Parameters:
        - open: An open window function.
        - dismiss: A dismiss window function.
     
     Setted functions example.
     
            @Environment(\.openWindow) var openWindow
            @Environment(\.dismissWindow) var dismissWindow
            
            ...
            
            pendant_controller.set_windows_functions
            {
                openWindow(id: SPendantDefaultID)
            }
            _:
            {
                dismissWindow(id: SPendantDefaultID)
            }
     */
    public func set_windows_functions(
        _ open: @escaping () -> (),
        _ dismiss: @escaping () -> ()
    )
    {
        self.open = open
        self.dismiss = dismiss
    }
}
