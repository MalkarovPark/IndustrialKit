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
    @Published var selection: pendant_selection_type = .none
    
    public func view_workspace()
    {
        selection = .workspace
    }
    
    public func view_robot(name: String)
    {
        selection = .robot
    }
    
    public func view_tool(name: String)
    {
        selection = .tool
    }
    
    public func view_dismiss()
    {
        selection = .none
    }
    
    //MARK: - Data
    @Published var text = String()
}

public enum pendant_selection_type: Equatable, CaseIterable
{
    case none
    case workspace
    case robot
    case tool
}
#endif
