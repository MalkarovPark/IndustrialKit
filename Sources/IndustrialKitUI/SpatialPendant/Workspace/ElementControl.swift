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
    
    @Binding var is_vertical: Bool
    
    @State private var is_expanded = false
    @State private var is_central_pressed = false
    
    let on_expand: () -> ()
    let on_collapse: () -> ()
    
    @Namespace private var pane_glass
    
    private let element_button_height: CGFloat = 48
    #if os(macOS)
    private let element_button_min_height: CGFloat = 20
    #else
    private let element_button_min_height: CGFloat = 24
    #endif
    
    public init(
        workspace: Workspace,
        
        is_vertical: Binding<Bool> = .constant(false),
        
        on_expand: @escaping () -> Void = {},
        on_collapse: @escaping () -> Void = {}
    )
    {
        self.workspace = workspace
        
        self._is_vertical = is_vertical
        
        self.on_expand = on_expand
        self.on_collapse = on_collapse
    }
    
    public var body: some View
    {
        ZStack//(alignment: !is_expanded ? .center : .bottomTrailing)
        {
            if !is_expanded
            {
                // Element Pane
                VStack
                {
                    Spacer()
                    
                    MarqueeText(
                        workspace.current_element.info,
                        font: .system(size: 10),
                        leading_inset: 12
                    )
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: is_expanded)
                    .frame(height: (120 - 48) / 2)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged
                        { _ in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                            {
                                is_central_pressed = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                                {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
                                    {
                                        is_central_pressed = false
                                    }
                                }
                            }
                        }
                        .onEnded
                        { _ in
                            tap_action()
                        }
                        .simultaneously(
                            with:
                                TapGesture()
                                .onEnded
                                {
                                    is_central_pressed = false
                                    
                                    tap_action()
                                }
                            )
                )
                .frame(width: 120, height: 120)
                .help(workspace.current_element.info)
            }
            else
            {
                // Editor
                VStack(alignment: .leading, spacing: 0)
                {
                    Button(action: collapse_tap_action)
                    {
                        Image(systemName: "xmark")
                            .padding(10)
                        #if os(iOS)
                            .font(.system(size: 16))
                        #endif
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .tint(.black)
                    #endif
                    .buttonBorderShape(.circle)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                    
                    VStack//(spacing: 0)
                    {
                        GroupBox
                        {
                            if !is_vertical { Spacer(minLength: 0) }
                            
                            ProductionProgramElementView(element: workspace.current_element, workspace: workspace, program: workspace.selected_program ?? ProductionProgram())
                                .padding(4)
                            
                            if !is_vertical { Spacer(minLength: 0) }
                        }
                    }
                    .padding(.horizontal, 10)
                    //.padding([.horizontal, .bottom], 10)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: element_button_min_height + 9.5 * 2)
                }
                /*.frame(
                    width: is_vertical ? expanded_element_control_width : element_control_width,
                    height: is_vertical ? nil : expanded_element_control_height
                )*/
                .frame(width: element_control_width) //, height: element_control_height)
                .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
            }
        }
        .overlay(alignment: !is_expanded ? .center : .bottom)
        {
            // Element Button
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
                        .frame(
                            width: !is_expanded ? element_button_height : (element_control_width - 20) / 2,
                            height: !is_expanded ? element_button_height : element_button_min_height
                        )
                        .scaleEffect(!is_expanded ? 1 : 0.75)
                        //.frame(width: 48, height: 48)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .glassEffect(.regular.tint(workspace.current_element.color), in: .rect(cornerRadius: 10, style: .continuous))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .padding(9.5)//(10)
        }
        .overlay(alignment: .top)
        {
            // New Element Menu
            VStack
            {
                Menu
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
                label:
                {
                    #if os(macOS) || os(iOS)
                    Text(workspace.current_element.title)
                        .font(
                            .system(
                                size: {
                                #if os(macOS)
                                    14
                                #elseif os(iOS)
                                    16
                                #endif
                                }(),
                                design: .rounded
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .frame(
                            height: !is_expanded
                            ? {
                            #if os(macOS)
                                16
                            #elseif os(iOS)
                                16
                            #endif
                            }()
                            : {
                            #if os(macOS)
                                12
                            #elseif os(iOS)
                                16
                            #endif
                            }()
                        )
                    #else
                    Text(workspace.current_element.title)
                        .font(.system(size: !is_expanded ? 16 : 18, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .frame(height: !is_expanded ? 16 : 24)
                    #endif
                }
                .menuIndicator(.hidden)
                .buttonStyle(.plain)
                .padding(10)
                #if os(iOS)
                .tint(.black)
                #elseif os(visionOS)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                #endif
                
                Spacer()
            }
            .frame(width: 120, height: 120)
        }
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
        .scaleEffect(is_central_pressed ? 1.05 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: workspace.current_element)
        .zIndex(1)
        #if os(visionOS)
        .offset(z: 2)
        #endif
    }
    
    // MARK: – Central press actions
    private func tap_action()
    {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85))
        {
            is_expanded = true
            
            on_expand()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                is_central_pressed = false
            }
        }
    }
    
    private func collapse_tap_action()
    {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75))
        {
            is_expanded = false
            
            on_collapse()
        }
    }
}

private struct MarqueeText: View
{
    let text: String
    var font: Font
    var spacing: CGFloat
    var points_per_second: CGFloat
    var pause_duration: Duration
    var leading_inset: CGFloat
    
    @State private var text_width: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var needs_scrolling = false
    
    private let gradient_margin: CGFloat = 0.04
    private let gradient_gap: CGFloat = 0.08
    
    init(
        _ text: String,
        font: Font = .system(size: 16),
        spacing: CGFloat = 32,
        points_per_second: CGFloat = 30,
        pause_duration: Duration = .seconds(1.5),
        leading_inset: CGFloat = 0
    )
    {
        self.text = text
        self.font = font
        self.spacing = spacing
        self.points_per_second = points_per_second
        self.pause_duration = pause_duration
        self.leading_inset = leading_inset
    }
    
    var body: some View
    {
        GeometryReader
        { geometry in
            let viewport_width = geometry.size.width
            //let needs_scrolling = text_width > viewport_width
            let distance = text_width + spacing
            let duration = Double(distance / max(points_per_second, 1))
            
            HStack(spacing: spacing)
            {
                Text(text)
                    .fixedSize()
                
                if needs_scrolling
                {
                    Text(text)
                        .fixedSize()
                        .accessibilityHidden(true)
                }
            }
            .font(font)
            .offset(x: offset)
            //.frame(height: geometry.size.height, alignment: .leading)
            .frame(
                width: needs_scrolling ? nil : viewport_width,
                height: geometry.size.height,
                alignment: needs_scrolling ? .leading : .center
            )
            .padding(.leading, needs_scrolling ? leading_inset : 0)
            .clipped()
            .background
            {
                Text(text)
                    .font(font)
                    .fixedSize()
                    .hidden()
                    .background
                {
                    GeometryReader
                    { text_geometry in
                        Color.clear
                            .onAppear
                        {
                            text_width = text_geometry.size.width
                        }
                        .onChange(of: text_geometry.size.width)
                        { _, new_width in
                            text_width = new_width
                        }
                    }
                }
            }
            .task(id: "\(text)-\(text_width)-\(viewport_width)")
            {
                offset = 0
                guard needs_scrolling else { return }
                
                while !Task.isCancelled
                {
                    try? await Task.sleep(for: pause_duration)
                    guard !Task.isCancelled else { break }
                    
                    withAnimation(.linear(duration: duration))
                    {
                        offset = -distance
                    }
                    try? await Task.sleep(for: .seconds(duration))
                    guard !Task.isCancelled else { break }
                    
                    var transaction = Transaction()
                    transaction.animation = nil
                    withTransaction(transaction) { offset = 0 }
                }
            }
            .onAppear { needs_scrolling = text_width > viewport_width }
        }
        .accessibilityLabel(text)
        .mask
        {
            if needs_scrolling
            {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: gradient_margin),
                        .init(color: .black, location: gradient_margin + gradient_gap),
                        .init(color: .black, location: 1 - gradient_margin - gradient_gap),
                        .init(color: .clear, location: 1 - gradient_margin)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            else
            {
                Rectangle()
            }
        }
    }
}

#if os(macOS)
internal let element_control_width: CGFloat = 240
internal let element_control_height: CGFloat = 260 //240
#elseif os(iOS)
internal let element_control_width: CGFloat = 320
internal let element_control_height: CGFloat = 370 //320
#elseif os(visionOS)
internal let element_control_width: CGFloat = 320
internal let element_control_height: CGFloat = 420 //320
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
    case wait = "Wait"
    
    public var element: LogicElement
    {
        switch self
        {
        case .jump: JumpLogicElement()
        case .comparator: ComparatorLogicElement()
        case .mark: MarkLogicElement()
        case .wait: WaitLogicElement()
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
            case let element as WaitLogicElement:
                WaitLogicElementView(element: element, workspace: workspace, program: program, on_update: on_update)
                
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
        
        @State var is_vertical = true
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                ElementControl(workspace: workspace, is_vertical: $is_vertical)
                    .frame(maxWidth: element_control_width)
                    .padding()
            }
            #if !os(visionOS)
            .frame(width: 400, height: 440)
            #endif
            .onAppear { prepare_workspace() }
            .overlay(alignment: .topLeading)
            {
                Button(is_vertical ? "Vertical" : "Horizontal")
                {
                    is_vertical.toggle()
                }
            }
        }
        
        private func prepare_workspace()
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
    
    static var previews: some View
    {
        Container()
            .padding()
    }
}
