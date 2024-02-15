//
//  File.swift
//  
//
//  Created by Malkarov Park on 10.02.2024.
//

#if os(visionOS)
import Foundation

/**
 A class that provides integration between applications and the Spatial Pendant.
 */
@available(visionOS 1.0, *)
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class PendantController: ObservableObject
{
    public init()
    {
        
    }
    
    //MARK: - Windows management
    private var is_opened = false
    
    ///Opens s-pendant window.
    public func open_pendant()
    {
        if !is_opened
        {
            open()
            is_opened = true
        }
    }
    
    ///Dismiss s-pendant window.
    public func dismiss_pendant()
    {
        if is_opened
        {
            dismiss()
            is_opened = false
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
    public func set_windows_functions(_ open: @escaping () -> (), _ dismiss: @escaping () -> ())
    {
        self.open = open
        self.dismiss = dismiss
    }
    
    private var open = {}
    private var dismiss = {}
    
    //MARK: - Event functions
    @Published var view_type: pendant_selection_type? //pendant_view_type
    
    @Published var workspace = Workspace()
    
    public func view_workspace()
    {
        view_type = .workspace
    }
    
    public func view_robot(name: String)
    {
        workspace.select_robot(name: name)
        view_type = .robot
    }
    
    public func view_tool(name: String)
    {
        workspace.select_tool(name: name)
        view_type = .tool
    }
    
    public func view_dismiss()
    {
        if workspace.any_object_selected
        {
            workspace.deselect_object()
        }
        
        view_type = nil
    }
    
    //MARK: - UI functions
    public var add_item_button_avaliable: Bool
    {
        switch view_type
        {
        case .workspace:
            return true
        case .robot:
            return workspace.selected_robot.programs_count > 0
        case .tool:
            return workspace.selected_tool.programs_count > 0
        case nil:
            return false
        }
    }
    
    //MARK: - New data
    @Published var new_opcode_value = Int()
    
    //MARK: - Document data
    @Published var update_workspace_in_document = false
    @Published var update_robot_in_document = false
    @Published var update_tool_in_document = false
}

public enum pendant_selection_type: Equatable, CaseIterable
{
    case workspace
    case robot
    case tool
}
#endif
