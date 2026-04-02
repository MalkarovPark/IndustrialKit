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
            GlassEffectContainer
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
                    .frame(width: 120) //.frame(maxWidth: .infinity)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(is_central_pressed ? 0.95 : 1)
                    .animation(
                        .interactiveSpring(response: 0.35, dampingFraction: 0.6, blendDuration: 0),
                        value: is_central_pressed
                    )
                    .onTapGesture
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
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.0)))
                    .help(workspace.current_element.info)
                }
                else
                {
                    // Editor
                    VStack(spacing: 0)
                    {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                is_expanded = false
                            }
                        })
                        {
                            Image(systemName: "chevron.compact.down")
                            #if !os(macOS)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 16)
                            #endif
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .scaleEffect(is_expanded ? 1 : 0.01)
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                        //.animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
                        
                        VStack
                        {
                            GroupBox
                            {
                                WorkspaceProgramElementView(element: workspace.current_element, workspace: workspace, program: workspace.selected_program ?? ProductionProgram())
                                    .padding(4)
                            }
                            
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
                            #if os(iOS)
                            .padding(.vertical, 4)
                            #endif
                        }
                        .padding(10)
                    }
                    #if os(macOS)
                    .frame(width: is_expanded ? 280 : 120)
                    #else
                    .frame(width: is_expanded ? 320 : 120)
                    #endif
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
                }
            }
            
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
                        .imageScale(.large)
                        .animation(.easeInOut(duration: 0.2), value: workspace.current_element.image)
                        .animation(.easeInOut(duration: 0.2), value: workspace.current_element.color)
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                        .frame(width: 48, height: 48)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive().tint(workspace.current_element.color), in: .rect(cornerRadius: 16, style: .continuous))
            #if os(macOS) || os(iOS)
            .padding(10)
            #else
            .padding(16)
            #endif
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
        }
    }
}

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

public struct WorkspaceProgramElementView: View
{
    @ObservedObject var element: WorkspaceProgramElement
    @ObservedObject var workspace: Workspace
    @ObservedObject var program: ProductionProgram
    
    let on_update: () -> ()
    
    public init(
        element: WorkspaceProgramElement,
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
                Text("Clean all registers")
                
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
            .frame(width: 400, height: 440)
            .onAppear
            {
                let robot = Robot(name: "6DOF")
                robot.is_placed = true
                robot.add_program(PositionProgram(name: "Square"))
                
                let tool = Tool(name: "Gripper")
                tool.is_placed = true
                tool.add_program(OperationProgram(name: "Close"))
                
                workspace.robots.append(robot)
                workspace.tools.append(tool)
            }
        }
    }
    
    static var previews: some View
    {
        Container()
            .padding()
    }
}
