//
//  ModifierElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 26.11.2023.
//

import SwiftUI
import IndustrialKit

public struct MoverElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var workspace: Workspace
    
    @State private var move_type: ModifierCopyType = .duplicate
    @State private var indices = [Int]()
    
    private let on_update: () -> ()
    
    public init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _move_type = State(initialValue: (_element.wrappedValue as! MoverModifierElement).move_type)
        _indices = State(initialValue: [(_element.wrappedValue as! MoverModifierElement).from_index, (_element.wrappedValue as! MoverModifierElement).to_index])
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            Picker("Type", selection: $move_type)
            {
                ForEach(ModifierCopyType.allCases, id: \.self)
                { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .padding(.trailing)
            
            RegistersSelector(text: "From \(indices[0]) to \(indices[1])", registers_count: workspace.registers.count, colors: registers_colors, indices: $indices, names: ["From", "To"])
        }
        .onChange(of: move_type)
        { _, new_value in
            (element as! MoverModifierElement).move_type = new_value
            on_update()
        }
        .onChange(of: indices)
        { _, new_value in
            (element as! MoverModifierElement).from_index = new_value[0]
            (element as! MoverModifierElement).to_index = new_value[1]
            on_update()
        }
    }
}

public struct WriterElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var workspace: Workspace
    
    @State private var value: Float = 0
    @State private var to_index = [Int]()
    
    private let on_update: () -> ()
    
    public init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _value = State(initialValue: (_element.wrappedValue as! WriterModifierElement).value)
        _to_index = State(initialValue: [(_element.wrappedValue as! WriterModifierElement).to_index])
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            HStack(spacing: 8)
            {
                Text("Write")
                #if !os(visionOS)
                    .frame(width: 34)
                #else
                    .frame(width: 60)
                #endif
                TextField("0", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if !os(macOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $value, in: -1000...1000)
                    .labelsHidden()
            }
            .padding(.trailing)
            
            RegistersSelector(text: "to \(to_index[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $to_index, names: ["To"])
        }
        .onChange(of: value)
        { _, new_value in
            (element as! WriterModifierElement).value = new_value
            on_update()
        }
        .onChange(of: to_index)
        { _, new_value in
            (element as! WriterModifierElement).to_index = new_value[0]
            on_update()
        }
    }
}

public struct MathElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var workspace: Workspace
    
    @State var operation: MathType = .add
    @State var value_index = [Int]()
    @State var value2_index = [Int]()
    
    @State private var picker_is_presented = false
    
    private let on_update: () -> ()
    
    public init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _operation = State(initialValue: (_element.wrappedValue as! MathModifierElement).operation)
        _value_index = State(initialValue: [(_element.wrappedValue as! MathModifierElement).value_index])
        _value2_index = State(initialValue: [(_element.wrappedValue as! MathModifierElement).value2_index])
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 8)
        {
            Text("Value of")
            
            RegistersSelector(text: "\(value_index[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $value_index, names: ["Value 1"])
            
            Button(operation.rawValue)
            {
                picker_is_presented = true
            }
            .popover(isPresented: $picker_is_presented)
            {
                MathTypePicker(operation: $operation)
                #if !os(macOS)
                    .presentationDetents([.height(96)])
                #endif
            }
            
            Text("value of")
            
            RegistersSelector(text: "\(value2_index[0])", registers_count: workspace.registers.count, colors: registers_colors, indices: $value2_index, names: ["Value 2"])
        }
        .onChange(of: operation)
        { _, new_value in
            (element as! MathModifierElement).operation = new_value
            on_update()
        }
        .onChange(of: value_index)
        { _, new_value in
            (element as! MathModifierElement).value_index = new_value[0]
            on_update()
        }
        .onChange(of: value2_index)
        { _, new_value in
            (element as! MathModifierElement).value2_index = new_value[0]
            on_update()
        }
    }
}

public struct MathTypePicker: View
{
    @Binding var operation: MathType
    
    public init(operation: Binding<MathType>)
    {
        self._operation = operation
    }
    
    public var body: some View
    {
        Picker("Operation", selection: $operation)
        {
            ForEach(MathType.allCases, id: \.self)
            { math_type in
                Text(math_type.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding()
    }
}

public struct ChangerElementView: View
{
    @EnvironmentObject var workspace: Workspace
    
    @Binding var element: WorkspaceProgramElement
    
    @State private var module_name = String()
    
    let on_update: () -> ()
    
    public init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _module_name = State(initialValue: (_element.wrappedValue as! Changer).module_name)
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        // MARK: Changer subview
        #if os(macOS)
        HStack
        {
            Picker("Module", selection: $module_name) // Changer module picker
            {
                if Changer.internal_modules_list.count > 0 || Changer.external_modules_list.count > 0
                {
                    Section(header: Text("Internal"))
                    {
                        ForEach(Changer.internal_modules_list, id: \.self)
                        {
                            Text($0).tag($0)
                        }
                    }
                    
                    Section(header: Text("External"))
                    {
                        ForEach(Changer.external_modules_list, id: \.self)
                        {
                            Text($0).tag(".\($0)")
                        }
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .onAppear
            {
                if Changer.internal_modules_list.count > 0 && module_name == ""
                {
                    module_name = Changer.internal_modules_list[0]
                }
            }
            .disabled(Changer.internal_modules_list.count == 0 && Changer.external_modules_list.count == 0)
        }
        .onChange(of: module_name)
        { _, new_value in
            (element as! ChangerModifierElement).module_name = new_value
            on_update()
        }
        #else
        VStack
        {
            Picker("Module", selection: $module_name) // Changer module picker
            {
                if Changer.internal_modules_list.count > 0
                {
                    Section(header: Text("Internal"))
                    {
                        ForEach(Changer.internal_modules_list, id: \.self)
                        {
                            Text($0).tag($0)
                        }
                    }
                    
                    Section(header: Text("External"))
                    {
                        ForEach(Changer.external_modules_list, id: \.self)
                        {
                            Text($0).tag(".\($0)")
                        }
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .onAppear
            {
                if Changer.internal_modules_list.count > 0 && module_name == ""
                {
                    module_name = Changer.internal_modules_list[0]
                }
            }
            .disabled(Changer.internal_modules_list.count == 0 && Changer.external_modules_list.count == 0)
        }
        .onChange(of: module_name)
        { _, new_value in
            (element as! ChangerModifierElement).module_name = new_value
            on_update()
        }
        #endif
    }
}

public struct OutputValueItmeView: View
{
    @EnvironmentObject var workspace: Workspace
    
    @Binding var from: Int
    @Binding var to: Int
    
    public var body: some View
    {
        HStack
        {
            Text("From")
            TextField("0", value: $from, format: .number)
            Stepper("Enter", value: $from, in: 0...10000)
                .labelsHidden()
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
            
            RegistersSelector(text: "to \(to)", registers_count: workspace.registers.count, colors: registers_colors, indices: binding_for_single($to), names: ["To"])
        }
    }
    
    private func binding_for_single(_ value: Binding<Int>) -> Binding<[Int]>
    {
        Binding(
            get:
                {
                    [value.wrappedValue]
                },
            set:
                { newValue in
                if let firstValue = newValue.first
                {
                    value.wrappedValue = firstValue
                }
            }
        )
    }
}

public struct ObserverElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var object_type: ObserverObjectType = .robot
    @State private var object_name = ""
    @State private var from_indices = [Int]()
    @State private var to_indices = [Int]()
    
    private let on_update: () -> ()
    
    @EnvironmentObject var workspace: Workspace
    
    @State private var viewed_object: WorkspaceObject?
    
    public init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _object_type = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).object_type)
        _object_name = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).object_name)
        _from_indices = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).from_indices)
        _to_indices = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).to_indices)
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        // MARK: tool subview
        VStack(spacing: 0)
        {
            Picker("Type", selection: $object_type)
            {
                ForEach(ObserverObjectType.allCases, id: \.self)
                { object_type in
                    Text(object_type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.bottom)
            
            switch object_type
            {
            case .robot:
                if workspace.placed_robots_names.count > 0
                {
                    Picker("Name", selection: $object_name) // robot picker
                    {
                        ForEach(workspace.placed_robots_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: object_name)
                    { _, new_value in
                        viewed_object = workspace.robot_by_name(new_value)
                        workspace.update_view()
                    }
                    .onAppear
                    {
                        if object_name == ""
                        {
                            object_name = workspace.placed_robots_names[0]
                        }
                        else
                        {
                            viewed_object = workspace.robot_by_name(object_name)
                            workspace.update_view()
                        }
                    }
                    #if !os(macOS)
                    .modifier(PickerNamer(name: "Name"))
                    #endif
                    .disabled(workspace.placed_robots_names.count == 0)
                    .padding(.bottom)
                }
                
                if workspace.placed_robots_names.count > 0
                {
                    if from_indices.count > 0
                    {
                        List
                        {
                            ForEach(from_indices.indices, id: \.self)
                            { index in
                                OutputValueItmeView(from: $from_indices[index], to: $to_indices[index])
                                    .contextMenu
                                    {
                                        Button(role: .destructive)
                                        {
                                            delete_items(at: IndexSet(integer: index))
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete(perform: delete_items)
                        }
                        .frame(minHeight: 160)
                        /*#if os(macOS)
                        .frame(height: 256) // (width: 256, height: 256)
                        #else
                        .frame(width: 320, height: 256)
                        #endif*/
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    else
                    {
                        ZStack
                        {
                            Rectangle()
                                .foregroundStyle(.white)
                            
                            Text("No items to ouput")
                        }
                        .frame(height: 64) // (width: 256, height: 256)
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    
                    Button(action: add_item)
                    {
                        Text("Add")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                else
                {
                    Text("No robots placed")
                }
            case .tool:
                if workspace.placed_tools_names.count > 0
                {
                    Picker("Name", selection: $object_name) // tool picker
                    {
                        ForEach(workspace.placed_tools_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: object_name)
                    { _, new_value in
                        viewed_object = workspace.tool_by_name(new_value)
                        workspace.update_view()
                    }
                    .onAppear
                    {
                        if object_name == ""
                        {
                            object_name = workspace.placed_tools_names[0]
                        }
                        else
                        {
                            viewed_object = workspace.tool_by_name(object_name)
                            workspace.update_view()
                        }
                    }
                    #if !os(macOS)
                    .modifier(PickerNamer(name: "Name"))
                    #endif
                    .disabled(workspace.placed_tools_names.count == 0)
                    .padding(.bottom)
                }
                
                if workspace.placed_tools_names.count > 0
                {
                    if from_indices.count > 0
                    {
                        List
                        {
                            ForEach(from_indices.indices, id: \.self)
                            { index in
                                OutputValueItmeView(from: $from_indices[index], to: $to_indices[index])
                                    .contextMenu
                                    {
                                        Button(role: .destructive)
                                        {
                                            delete_items(at: IndexSet(integer: index))
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete(perform: delete_items)
                        }
                        .frame(minHeight: 160)
                        /*#if os(macOS)
                        .frame(height: 256) // (width: 256, height: 256)
                        #else
                        .frame(width: 320, height: 256)
                        #endif*/
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    else
                    {
                        ZStack
                        {
                            Rectangle()
                                .foregroundStyle(.white)
                            
                            Text("No items to ouput")
                        }
                        .frame(height: 64) // (width: 256, height: 256)
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    
                    Button(action: add_item)
                    {
                        Text("Add")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                else
                {
                    Text("No tools placed")
                }
            }
        }
        .onChange(of: object_type)
        { _, new_value in
            switch object_type
            {
            case .robot:
                if workspace.placed_robots_names.count > 0
                {
                    object_name = workspace.placed_robots_names[0]
                }
                else
                {
                    object_name = ""
                }
            case .tool:
                if workspace.placed_tools_names.count > 0
                {
                    object_name = workspace.placed_tools_names[0]
                }
                else
                {
                    object_name = ""
                }
            }
            
            (element as! ObserverModifierElement).object_type = new_value
            on_update()
        }
        .onChange(of: object_name)
        { _, new_value in
            (element as! ObserverModifierElement).object_name = new_value
            on_update()
        }
        .onChange(of: from_indices)
        { _, new_value in
            (element as! ObserverModifierElement).from_indices = new_value
            on_update()
        }
        .onChange(of: to_indices)
        { _, new_value in
            (element as! ObserverModifierElement).to_indices = new_value
            on_update()
        }
    }
    
    func add_item()
    {
        from_indices.append(0)
        to_indices.append(0)
    }
    
    func delete_items(at offsets: IndexSet)
    {
        from_indices.remove(atOffsets: offsets)
        to_indices.remove(atOffsets: offsets)
    }
}

//MARK: - Previews
struct IMAModifiersPreviewsContainer: PreviewProvider
{
    static var previews: some View
    {
        ModifiersContainer()
            .frame(height: 512)
    }

    struct ModifiersContainer: View
    {
        @StateObject var workspace = Workspace()

        var body: some View
        {
            ZStack
            {
                Rectangle()
                    .foregroundStyle(.white)
                
                ModifiersView()
                    .environmentObject(workspace)
                    .onAppear
                {
                    let robot = Robot(name: "6DOF")
                    robot.is_placed = true
                    robot.add_program(PositionsProgram(name: "Square"))
                    
                    let tool = Tool(name: "Gripper")
                    tool.is_placed = true
                    tool.add_program(OperationsProgram(name: "Close"))
                    
                    workspace.robots.append(robot)
                    workspace.tools.append(tool)
                    
                    Changer.internal_modules_list.append("Forces To Position")
                }
            }
        }
    }

    struct ModifiersView: View
    {
        var body: some View
        {
            VStack(alignment: .leading, spacing: 8)
            {
                /*Text("Modifiers")
                    .font(.custom("Line Seed Sans", size: 20))
                    .foregroundStyle(.pink)
                    .fontWeight(.medium)
                    .opacity(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], 8)*/

                HStack
                {
                    MoverElementView(element: .constant(MoverModifierElement()), on_update: {})
                        .padding()
                        .frame(width: 256)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 8)
                        .padding()

                    ChangerElementView(element: .constant(ChangerModifierElement()), on_update: {})
                        .padding()
                        .frame(width: 256)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 8)
                        .padding()
                }

                HStack
                {
                    ObserverElementView(element: .constant(ObserverModifierElement()), on_update: {})
                        .padding()
                        .frame(width: 256)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 8)
                        .padding()
                    
                    VStack
                    {
                        WriterElementView(element: .constant(WriterModifierElement()), on_update: {})
                            .padding()
                            .frame(width: 256)
                            .background(.bar)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 8)
                            .padding()

                        MathElementView(element: .constant(MathModifierElement()), on_update: {})
                            .padding()
                            .frame(width: 256)
                            .background(.bar)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 8)
                            .padding()
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(8)
        }
    }
}
