//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

public struct ElementControl: View
{
    @ObservedObject var workspace: Workspace
    
    @State private var is_expanded = false
    @State private var is_central_pressed = false
    
    @Namespace private var pane_glass
    
    public init(
        workspace: Workspace
    )
    {
        self.workspace = workspace
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            ZStack
            {
                if !is_expanded
                {
                    // Element Pane
                    HStack(spacing: 0)
                    {
                        VStack(alignment: .leading)
                        {
                            Text(workspace.current_element.title)
                                .font(.title3.scaled(by: 0.8))
                                .animation(.easeInOut(duration: 0.2), value: workspace.current_element.title)
                                .lineLimit(1)
                            
                            Text(workspace.current_element.info)
                                .font(.default.scaled(by: 0.8))
                                .foregroundColor(.secondary)
                                .animation(.easeInOut(duration: 0.2), value: workspace.current_element.info)
                                .lineLimit(1)
                        }
                        .padding(10)
                    }
                    .background(.clear)
                    .frame(width: element_panel_width)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    /*.onTapGesture
                    {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                        {
                            is_central_pressed = true
                            is_expanded = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                            {
                                is_central_pressed = false
                            }
                        }
                    }*/
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged
                            { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                {
                                    is_central_pressed = true
                                }
                            }
                            .onEnded
                            { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                {
                                    is_expanded = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                                    {
                                        is_central_pressed = false
                                    }
                                }
                            }
                            .simultaneously(
                                with:
                                    TapGesture()
                                    .onEnded
                                    {
                                        is_central_pressed = true
                                        
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                        {
                                            is_central_pressed = true
                                            is_expanded = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                                            {
                                                is_central_pressed = false
                                            }
                                        }
                                    }
                                )
                    )
                    .help(workspace.current_element.info)
                }
                else
                {
                    // Editor
                    VStack(spacing: 0)
                    {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
                            {
                                is_expanded = false
                            }
                        })
                        {
                            Image(systemName: "chevron.compact.down")
                                .padding(10)
                            #if os(iOS)
                                .font(.system(size: 16))
                            #endif
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .tint(.black)
                        #endif
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                        
                        VStack
                        {
                            GroupBox
                            {
                                ProductionProgramElementView(element: workspace.current_element, workspace: workspace, program: workspace.selected_program ?? ProductionProgram())
                                    .padding(4)
                            }
                            .frame(width: is_expanded ? element_control_width : 120)
                            
                            Menu("New Element")
                            {
                                Section(header: Text("Performer"))
                                {
                                    ForEach(PerformerType.allCases, id: \.self)
                                    { type in
                                        Button(type.rawValue)
                                        {
                                            workspace.current_element = type.element
                                        }
                                        .tag(type)
                                    }
                                }
                                
                                Section(header: Text("Modifier"))
                                {
                                    ForEach(ModifierType.allCases, id: \.self)
                                    { type in
                                        Button(type.rawValue)
                                        {
                                            workspace.current_element = type.element
                                        }
                                        .tag(type)
                                    }
                                }
                                
                                Section(header: Text("Logic"))
                                {
                                    ForEach(LogicType.allCases, id: \.self)
                                    { type in
                                        Button(type.rawValue)
                                        {
                                            workspace.current_element = type.element
                                        }
                                        .tag(type)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .buttonStyle(.borderless)
                            #if os(iOS)
                            .tint(.black)
                            .padding(.vertical, 4)
                            #endif
                        }
                        .padding([.horizontal, .bottom], 10)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
            .scaleEffect(is_central_pressed ? 1.05 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
            #if !os(visionOS)
            .padding(.trailing, 10)
            #else
            .padding(.trailing, 16)
            #endif
            .zIndex(1)
            
            Button
            {
                workspace.start_pause_single_element()
            }
            label:
            {
                ZStack
                {
                    workspace.current_element.image
                        .foregroundColor(.white)
                        .font(.system(size: 18)) //.imageScale(.large)
                        .animation(.easeInOut(duration: 0.2), value: workspace.current_element.image)
                        .animation(.easeInOut(duration: 0.2), value: workspace.current_element.color)
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    #if os(macOS)
                        .frame(width: 48, height: 48)
                    #elseif os(iOS)
                        .frame(width: 56, height: 56)
                    #elseif os(visionOS)
                        .frame(width: 56, height: 56)
                    #endif
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive().tint(workspace.current_element.color), in: .rect(cornerRadius: 16, style: .continuous))
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
        }
        #if os(visionOS)
        .offset(z: 2)
        #endif
    }
}

#if os(macOS)
internal let element_control_width: CGFloat = 272
internal let element_panel_width: CGFloat = 120
#elseif os(iOS)
internal let element_control_width: CGFloat = 370
internal let element_panel_width: CGFloat = 140
#elseif os(visionOS)
internal let element_control_width: CGFloat = 400
internal let element_panel_width: CGFloat = 160
#endif

//MARK: Type enums
///A performer program element type enum.
public enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    
    public var element: PerformerElement
    {
        switch self
        {
        case .robot: RobotPerformerElement()
        case .tool: ToolPerformerElement()
        }
    }
}

///A modifier program element type enum.
public enum ModifierType: String, Codable, Equatable, CaseIterable
{
    case mover = "Mover"
    case writer = "Writer"
    case math = "Math"
    case changer = "Changer"
    case observer = "Observer"
    case cleaner = "Cleaner"
    
    public var element: ModifierElement
    {
        switch self
        {
        case .mover: MoverModifierElement()
        case .writer: WriterModifierElement()
        case .math: MathModifierElement()
        case .changer: ChangerModifierElement()
        case .observer: ObserverModifierElement()
        case .cleaner: CleanerModifierElement()
        }
    }
}

///A logic program element type enum.
public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case comparator = "Comparator"
    case mark = "Mark"
    
    public var element: LogicElement
    {
        switch self
        {
        case .jump: JumpLogicElement()
        case .comparator: ComparatorLogicElement()
        case .mark: MarkLogicElement()
        }
    }
}

public struct ProductionProgramElementView: View
{
    @ObservedObject var element: ProductionProgramElement
    @ObservedObject var workspace: Workspace
    @ObservedObject var program: ProductionProgram
    
    let on_update: () -> ()
    
    public init(
        element: ProductionProgramElement,
        workspace: Workspace,
        program: ProductionProgram = ProductionProgram(),
        
        on_update: @escaping () -> Void = {}
    )
    {
        self.element = element
        self.workspace = workspace
        self.program = program
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        ZStack
        {
            switch element
            {
            case let element as RobotPerformerElement:
                RobotPerformerElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as ToolPerformerElement:
                ToolPerformerElementView(element: element, workspace: workspace, on_update: on_update)
                
            case let element as MoverModifierElement:
                MoverElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as WriterModifierElement:
                WriterElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as MathModifierElement:
                MathElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as ChangerModifierElement:
                ChangerElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as ObserverModifierElement:
                ObserverElementView(element: element, workspace: workspace, on_update: on_update)
            case let element as CleanerModifierElement:
                Text("Set all registers to 0")
                
            case let element as JumpLogicElement:
                JumpElementView(element: element, program: program, on_update: on_update)
            case let element as ComparatorLogicElement:
                ComparatorElementView(element: element, workspace: workspace, program: program, on_update: on_update)
            case let element as MarkLogicElement:
                MarkLogicElementView(element: element, workspace: workspace, program: program, on_update: on_update)
                
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }
}



// MARK: - Previews
struct ElementControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var workspace = Workspace()
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                ElementControl(workspace: workspace)
                    .padding()
            }
            #if !os(visionOS)
            .frame(width: 400, height: 440)
            #endif
            .onAppear
            {
                let robot = Robot(name: "6DOF Robot")
                robot.is_placed = true
                robot.add_program(PositionProgram(name: "Square"))
                
                let tool = Tool(name: "Gripper")
                tool.is_placed = true
                tool.add_program(OperationProgram(name: "Bite"))
                
                workspace.robots.append(robot)
                workspace.tools.append(tool)
                
                Changer.internal_modules_list.append("Random")
                Changer.external_modules_list.append("Defaults")
                
                if let element = workspace.current_element as? RobotPerformerElement, element.object_name == ""
                {
                    element.object_name = workspace.placed_robot_names.first ?? String()
                    
                    if workspace.robot(named: element.object_name).program_names.count > 0
                    {
                        element.program_name = workspace.robot(named: element.object_name).program_names.first ?? ""
                    }
                }
            }
        }
    }
    
    static var previews: some View
    {
        Container()
            .padding()
    }
}
