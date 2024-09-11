//
//  SwiftUIView.swift
//  
//
//  Created by Artem on 15.02.2024.
//

#if os(visionOS)
import SwiftUI
import UniformTypeIdentifiers

//MARK: - Workspace
internal struct WorkspaceProgramView: View
{
    @State private var program_columns = Array(repeating: GridItem(.flexible()), count: 1)
    @State private var dragged_element: WorkspaceProgramElement?
    @State private var add_element_view_presented = false
    
    @State private var appeared = false
    
    @EnvironmentObject var workspace: Workspace
    @EnvironmentObject var controller: PendantController
    
    var body: some View
    {
        ScrollView
        {
            LazyVGrid(columns: program_columns)
            {
                ForEach(workspace.elements)
                { element in
                    ProgramElementItemView(elements: $workspace.elements, element: element, on_delete: remove_elements)
                    .onDrag({
                        self.dragged_element = element
                        return NSItemProvider(object: element.id.uuidString as NSItemProviderWriting)
                    }, preview: {
                        ElementCardView(title: element.title, info: element.info, image: element.image, color: element.color)
                    })
                    .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $workspace.elements, dragged_element: $dragged_element, workspace_elements: workspace.file_data().elements, element: element))
                }
                .padding(4)
                .onChange(of: workspace.elements)
                {_, _ in
                    if appeared
                    {
                        controller.elements_document_data_update.toggle()
                    }
                }
                .onAppear
                {
                    appeared = true
                }
                
                Spacer(minLength: 64)
            }
            .padding()
            .disabled(workspace.performed)
        }
        .animation(.spring(), value: workspace.elements)
    }
    
    func remove_elements(at offsets: IndexSet) //Remove program element function
    {
        withAnimation
        {
            workspace.elements.remove(atOffsets: offsets)
        }
    }
}

internal struct WorkspaceDropDelegate : DropDelegate
{
    @Binding var elements : [WorkspaceProgramElement]
    @Binding var dragged_element : WorkspaceProgramElement?
    
    @State var workspace_elements: [WorkspaceProgramElementStruct]
    
    let element: WorkspaceProgramElement
    
    func performDrop(info: DropInfo) -> Bool
    {
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_element = self.dragged_element else
        {
            return
        }
        
        if dragged_element != element
        {
            let from = elements.firstIndex(of: dragged_element) ?? 0
            let to = elements.firstIndex(of: element) ?? 0
            
            withAnimation(.default)
            {
                self.elements.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

internal struct ProgramElementItemView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    
    @State var element: WorkspaceProgramElement
    @State var element_view_presented = false
    @State private var is_current = false
    
    @State private var is_deliting = false
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ZStack
        {
            ElementCardView(title: element.title, info: element.info, image: element.image, color: element.color, is_current: workspace.is_current_element(element: element))
                .onTapGesture
            {
                element_view_presented = true
            }
            
            if !is_deliting && !(element is CleanerModifierElement)
            {
                Rectangle()
                    .foregroundStyle(.clear)
                    //.popover(isPresented: $element_view_presented, arrowEdge: .trailing)
                    .sheet(isPresented: $element_view_presented)
                    {
                        VStack(spacing: 0)
                        {
                            Spacer(minLength: 72)
                            
                            ElementView(element: $element, on_update: update_program_element)
                        }
                        .modifier(ViewCloseButton(is_presented: $element_view_presented))
                    }
            }
        }
        .disabled(is_deliting)
        .contextMenu
        {
            Button(action: duplicate_program_element)
            {
                Label("Duplicate", systemImage: "square.on.square")
            }
            Button(role: .destructive, action: {
                delete_program_element()
            })
            {
                Label("Delete", systemImage: "xmark")
            }
        }
    }
    
    //MARK: Program elements manage functions
    private func update_program_element()
    {
        workspace.elements_check()
        controller.elements_document_data_update.toggle()
    }
    
    private func duplicate_program_element()
    {
        let new_program_element_data = element.file_info
        var new_program_element = WorkspaceProgramElement()
        
        switch new_program_element_data.identifier
        {
        case .robot_performer:
            new_program_element = RobotPerformerElement(element_struct: new_program_element_data)
        case .tool_performer:
            new_program_element = ToolPerformerElement(element_struct: new_program_element_data)
        case .mover_modifier:
            new_program_element = MoverModifierElement(element_struct: new_program_element_data)
        case .writer_modifier:
            new_program_element = WriterModifierElement(element_struct: new_program_element_data)
        case .math_modifier:
            new_program_element = MathModifierElement(element_struct: new_program_element_data)
        case .changer_modifier:
            new_program_element = ChangerModifierElement(element_struct: new_program_element_data)
        case .observer_modifier:
            new_program_element = ObserverModifierElement(element_struct: new_program_element_data)
        case .cleaner_modifier:
            new_program_element = CleanerModifierElement(element_struct: new_program_element_data)
        case .jump_logic:
            new_program_element = JumpLogicElement(element_struct: new_program_element_data)
        case .comparator_logic:
            new_program_element = ComparatorLogicElement(element_struct: new_program_element_data)
        case .mark_logic:
            new_program_element = MarkLogicElement(element_struct: new_program_element_data)
        case .none:
            break
        }
        
        workspace.elements.append(new_program_element)
        
        workspace.elements_check()
        controller.elements_document_data_update.toggle()
    }
    
    private func delete_program_element()
    {
        is_deliting = true
        if let index = elements.firstIndex(of: element)
        {
            self.on_delete(IndexSet(integer: index))
            workspace.elements_check()
        }
        
        workspace.update_view()
        controller.elements_document_data_update.toggle()
        
        element_view_presented.toggle()
    }
}

internal struct ElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    let on_update: () -> ()
    
    var body: some View
    {
        ZStack
        {
            switch element
            {
            case is RobotPerformerElement:
                RobotPerformerElementView(element: $element, on_update: on_update)
            case is ToolPerformerElement:
                ToolPerformerElementView(element: $element, on_update: on_update)
            case is MoverModifierElement:
                MoverElementView(element: $element, on_update: on_update)
            case is WriterModifierElement:
                WriterElementView(element: $element, on_update: on_update)
            case is MathModifierElement:
                MathElementView(element: $element, on_update: on_update)
            case is ChangerModifierElement:
                ChangerElementView(element: $element, on_update: on_update)
            case is ObserverModifierElement:
                ObserverElementView(element: $element, on_update: on_update)
            case is CleanerModifierElement:
                EmptyView()
            case is JumpLogicElement:
                JumpElementView(element: $element, on_update: on_update)
            case is ComparatorLogicElement:
                ComparatorElementView(element: $element, on_update: on_update)
            case is MarkLogicElement:
                MarkLogicElementView(element: $element, on_update: on_update)
            default:
                EmptyView()
            }
        }
        .padding()
    }
}

//MARK: View modifiers
internal struct PickerNamer: ViewModifier
{
    var name: String
    
    public func body(content: Content) -> some View
    {
        HStack(spacing: 0)
        {
            Text(name)
                .padding(.trailing)
            content
        }
    }
}

//MARK: Type enums
///A program element type enum.
public enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modifier = "Modifier"
    case logic = "Logic"
}

///A performer program element type enum.
public enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
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
}

///A logic program element type enum.
public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case comparator = "Comparator"
    case mark = "Mark"
}

private func colors_by_seed(seed: Int) -> [Color]
{
    var colors = [Color]()

    srand48(seed)
    
    for _ in 0..<256
    {
        var color = [Double]()
        for _ in 0..<3
        {
            let random_number = Double(drand48() * Double(128) + 64)
            
            color.append(random_number)
        }
        colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
    }

    return colors
}

let registers_colors = colors_by_seed(seed: 5433)

//MARK: - Robot
internal struct RobotProgramView: View
{
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            List
            {
                if workspace.selected_robot.programs_count > 0
                {
                    if workspace.selected_robot.selected_program.points_count > 0
                    {
                        ForEach(workspace.selected_robot.selected_program.points, id: \.self)
                        { point in
                            PositionItemView(points: $workspace.selected_robot.selected_program.points, point_item: point, on_delete: remove_points)
                                .onDrag
                                {
                                    return NSItemProvider()
                                }
                        }
                        .onMove(perform: point_item_move)
                        .onDelete(perform: remove_points)
                        .onChange(of: workspace.robots)
                        { _, _ in
                            controller.robots_document_data_update.toggle()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding([.horizontal, .top])
        }
    }
    
    private func point_item_move(from source: IndexSet, to destination: Int)
    {
        workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        workspace.selected_robot.selected_program.visual_build()
        controller.robots_document_data_update.toggle()
    }
    
    private func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            workspace.selected_robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        controller.robots_document_data_update.toggle()
        workspace.update_view()
        workspace.selected_robot.selected_program.selected_point_index = -1
    }
    
    private func delete_positions_program()
    {
        if workspace.selected_robot.programs_names.count > 0
        {
            let current_spi = workspace.selected_robot.selected_program_index
            workspace.selected_robot.delete_program(index: current_spi)
            if workspace.selected_robot.programs_names.count > 1 && current_spi > 0
            {
                workspace.selected_robot.selected_program_index = current_spi - 1
            }
            else
            {
                workspace.selected_robot.selected_program_index = 0
            }
            
            controller.robots_document_data_update.toggle()
            workspace.update_view()
        }
    }
    
    private func add_point_to_program()
    {
        workspace.selected_robot.selected_program.add_point(PositionPoint(x: workspace.selected_robot.pointer_location[0], y: workspace.selected_robot.pointer_location[1], z: workspace.selected_robot.pointer_location[2], r: workspace.selected_robot.pointer_rotation[0], p: workspace.selected_robot.pointer_rotation[1], w: workspace.selected_robot.pointer_rotation[2]))
        
        controller.robots_document_data_update.toggle()
        workspace.update_view()
    }
}

internal struct PositionItemView: View
{
    @Binding var points: [PositionPoint]
    
    @State var point_item: PositionPoint
    @State var position_item_view_presented = false
    
    @EnvironmentObject var workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(workspace.selected_robot.inspector_point_color(point: point_item))
            
            Spacer()
            
            HStack(spacing: 0)
            {
                Spacer()
                
                Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                    //.font(.caption)
                
                Spacer()
                
                Divider()
                
                Spacer()
                
                Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                    //.font(.caption)
                
                Spacer()
            }
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .leading)
            {
                PositionPointView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
            }
            
            Spacer()
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
}

internal struct PositionPointView: View
{
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    @State private var appeared = false
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack
            {
                PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                    .onChange(of: item_view_pos_location)
                    { _, _ in
                        update_point_location()
                    }
                    .onChange(of: item_view_pos_rotation)
                    { _, _ in
                        update_point_rotation()
                    }
            }
            .padding([.horizontal, .top])
            
            HStack
            {
                Picker("Type", selection: $item_view_pos_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 128)
                .buttonStyle(.borderedProminent)
                
                Text("Speed")
                    .frame(width: 60)
                TextField("0", value: $item_view_pos_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $item_view_pos_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
            .onChange(of: item_view_pos_type)
            { _, new_value in
                if appeared
                {
                    point_item.move_type = new_value
                    update_workspace_data()
                }
            }
            .onChange(of: item_view_pos_speed)
            { _, new_value in
                if appeared
                {
                    point_item.move_speed = new_value
                    update_workspace_data()
                }
            }
        }
        .onAppear()
        {
            workspace.selected_robot.selected_program.selected_point_index = workspace.selected_robot.selected_program.points.firstIndex(of: point_item) ?? -1
            
            item_view_pos_type = point_item.move_type
            item_view_pos_speed = point_item.move_speed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                appeared = true
            }
        }
        .onDisappear()
        {
            workspace.selected_robot.selected_program.selected_point_index = -1
        }
    }
    
    //MARK: Point manage functions
    func update_point_location()
    {
        point_item.x = item_view_pos_location[0]
        point_item.y = item_view_pos_location[1]
        point_item.z = item_view_pos_location[2]
        
        workspace.selected_robot.point_shift(&point_item)
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        point_item.r = item_view_pos_rotation[0]
        point_item.p = item_view_pos_rotation[1]
        point_item.w = item_view_pos_rotation[2]
        
        update_workspace_data()
    }
    
    func update_workspace_data()
    {
        workspace.update_view()
        workspace.selected_robot.selected_program.visual_build()
        
        controller.robots_document_data_update.toggle()
    }
}

//MARK: - Tool
internal struct ToolProgramView: View
{
    @Binding var tool: Tool
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            List
            {
                if workspace.selected_tool.programs_count > 0
                {
                    if workspace.selected_tool.selected_program.codes_count > 0
                    {
                        ForEach(workspace.selected_tool.selected_program.codes)
                        { code in
                            OperationItemView(codes: $workspace.selected_tool.selected_program.codes, code_item: code)
                                .onDrag
                            {
                                return NSItemProvider()
                            }
                        }
                        .onMove(perform: code_item_move)
                        .onDelete(perform: remove_codes)
                        .onChange(of: workspace.tools)
                        { _, _ in
                            controller.tools_document_data_update.toggle()
                        }
                    }
                }
            }
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        tool.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        controller.tools_document_data_update.toggle()
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            tool.selected_program.codes.remove(atOffsets: offsets)
        }
        
        controller.tools_document_data_update.toggle()
    }
}

internal struct OperationItemView: View
{
    @Binding var codes: [OperationCode]
    
    @State var code_item: OperationCode
    @State private var new_code = OperationCodeInfo()
    @State private var update_data = false
    
    @EnvironmentObject var controller: PendantController
    @EnvironmentObject var workspace: Workspace
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(workspace.selected_tool.inspector_code_color(code: code_item))
            
            Picker("Code", selection: $new_code)
            {
                if workspace.selected_tool.codes.count > 0
                {
                    ForEach(workspace.selected_tool.codes, id:\.self)
                    { code in
                        Text(code.name)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(workspace.selected_tool.codes.count == 0)
            .frame(maxWidth: .infinity)
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: new_code)
            { _, new_value in
                if update_data
                {
                    code_item.value = new_code.value
                    controller.tools_document_data_update.toggle()
                }
            }
        }
        .onAppear
        {
            update_data = false
            new_code = workspace.selected_tool.code_info(code_item.value)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                update_data = true
            }
        }
    }
    
    func delete_code_item()
    {
        workspace.selected_tool.selected_program.delete_code(index: workspace.selected_tool.selected_program.codes.firstIndex(of: code_item) ?? 0)
    }
}

#Preview
{
    RobotProgramView()
}

#Preview
{
    ToolProgramView(tool: .constant(Tool()))
}
#endif
