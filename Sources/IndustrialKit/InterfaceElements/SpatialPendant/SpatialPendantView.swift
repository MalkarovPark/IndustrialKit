//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 09.02.2024.
//

#if os(visionOS)
import SwiftUI

/**
 A view that provides the universal spatial pendant for industrial applications.
 
 This pendant can change its content according to selected *workspace*, *robot* or *tool*.
 */
@available(visionOS 1.0, *)
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct SpatialPendant: Scene
{
    var window_id: String
    let controller: PendantController
    let workspace: Workspace
    
    public init(window_id: String = SPendantDefaultID, controller: PendantController, workspace: Workspace = Workspace())
    {
        self.window_id = window_id
        self.controller = controller
        
        self.workspace = workspace
    }
    
    @SceneBuilder public var body: some Scene
    {
        WindowGroup(id: window_id)
        {
            SpatialPendantView()
                .environmentObject(controller)
                .onDisappear(perform: controller.dismiss_pendant)
        }
        .windowResizability(.contentSize)
    }
}

///The default widow id of Spatial Pendant.
public let SPendantDefaultID = "pendant"

private struct SpatialPendantView: View
{
    @EnvironmentObject var controller: PendantController
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                Text("Program")
                    .bold()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack
            {
                Text("Control")
                    .bold()
            }
            .frame(maxWidth: .infinity, maxHeight: 280)
            .background(.thinMaterial)
            .overlay(alignment: .bottomTrailing)
            {
                Button(action: {})
                {
                    ZStack
                    {
                        Image(systemName: "plus")
                            .resizable()
                            .imageScale(.large)
                            .padding()
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .glassBackgroundEffect()
                .frame(depth: 24)
                .padding(32)
            }
        }
        .frame(width: 512, height: 828)
        .ornament(attachmentAnchor: .scene(.trailing))
        {
            VStack(spacing: 0)
            {
                Button(action: {})
                {
                    ZStack
                    {
                        Rectangle()
                            .foregroundStyle(.red)
                            .glassBackgroundEffect()
                        Image(systemName: "stop")
                            .resizable()
                            .frame(width: 24, height: 24)
                            //.scaledToFit()
                            .padding()
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .padding([.horizontal, .top])
                
                Button(action: {})
                {
                    ZStack
                    {
                        Image(systemName: "playpause")
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .padding()
            }
            .glassBackgroundEffect()
        }
        .ornament(attachmentAnchor: .scene(.top))
        {
            if controller.selection == .robot || controller.selection == .tool
            {
                ProgramPicker()
            }
        }
    }
}

private struct ProgramPicker: View
{
    @State private var add_program_view_presented = false
    @State private var programs_names = ["Circle", "Square"]
    @State private var selected_program_index = 0
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Picker("Program", selection: $selected_program_index)
            {
                if programs_names.count > 0
                {
                    ForEach(0 ..< programs_names.count, id: \.self)
                    {
                        Text(programs_names[$0])
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .pickerStyle(.menu)
            //.disabled(base_workspace.selected_robot.programs_names.count == 0)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            
            Button(action: {})
            {
                Image(systemName: "minus")
            }
            .buttonBorderShape(.circle)
            .padding(.horizontal)
            
            Button(action: { add_program_view_presented.toggle() })
            {
                Image(systemName: "plus")
            }
            .buttonBorderShape(.circle)
            .popover(isPresented: $add_program_view_presented)
            {
                AddProgramView(add_program_view_presented: $add_program_view_presented)//, document: $document, selected_program_index: $base_workspace.selected_robot.selected_program_index)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}

struct AddProgramView: View
{
    @Binding var add_program_view_presented: Bool
    //@Binding var document: Robotic_Complex_WorkspaceDocument
    //@Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    //@EnvironmentObject var base_workspace: Workspace
    //@EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack
        {
            HStack(spacing: 12)
            {
                TextField("Name", text: $new_program_name)
                    .frame(minWidth: 128, maxWidth: 256)
                #if os(iOS) || os(visionOS)
                    .frame(idealWidth: 256)
                    .textFieldStyle(.roundedBorder)
                #endif
                
                Button("Add")
                {
                    if new_program_name == ""
                    {
                        new_program_name = "None"
                    }
                    
                    /*base_workspace.selected_robot.add_program(PositionsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_robot.programs_names.count - 1
                    
                    document.preset.robots = base_workspace.file_data().robots
                    app_state.get_scene_image = true
                    add_program_view_presented.toggle()*/
                }
                .fixedSize()
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
    }
}

//MARK: - Previews
#Preview
{
    SpatialPendantView()
}
#endif
