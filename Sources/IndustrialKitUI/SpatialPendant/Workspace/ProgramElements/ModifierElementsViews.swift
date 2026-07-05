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
    @ObservedObject var element: MoverModifierElement
    
    @ObservedObject var workspace: Workspace
    
    private let on_update: () -> ()
    
    public init(
        element: MoverModifierElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            let object_type = Binding(
                get: { element.move_type },
                set:
                    { new_value in
                        element.move_type = new_value
                        
                        on_update()
                    }
            )
            
            let links = Binding(
                get: { element.links },
                set:
                    { new_value in
                        element.links = new_value
                        
                        on_update()
                    }
            )
            
            Picker("Type", selection: object_type)
            {
                ForEach(ModifierMoveType.allCases, id: \.self)
                { object_type in
                    Text(object_type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.bottom)
            
            if links.count > 0
            {
                List
                {
                    ForEach($element.links)
                    { $link in
                        HStack
                        {
                            let link_indices = binding_for_link($link)
                            
                            RegistersSelector(
                                text: "From \(link.from) to \(link.to)",
                                registers_count: workspace.registers.count,
                                colors: default_register_colors,
                                indices: link_indices,
                                names: ["From", "To"]
                            )
                        }
                        .listRowSeparator(.hidden)
                        .contextMenu
                        {
                            Button(role: .destructive)
                            {
                                delete_item($link.wrappedValue)
                            }
                            label:
                            {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        #if os(iOS)
                        .frame(height: 2)
                        #endif
                        #if os(visionOS)
                        .listRowInsets(EdgeInsets(top: 16, leading: -10, bottom: 0, trailing: -10))
                        #endif
                    }
                    .onDelete
                    { offsets in
                        element.links.remove(atOffsets: offsets)
                    }
                }
                .frame(minHeight: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            else
            {
                ZStack
                {
                    #if !os(visionOS)
                    Rectangle()
                        .foregroundStyle(.white)
                    #endif
                    
                    Text("No values to \(element.move_type == .move ? "move" : "copy")")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            
            Button(action: add_item)
            {
                Text("Add")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            #if os(iOS)
            .buttonBorderShape(.roundedRectangle)
            #endif
            .keyboardShortcut(.defaultAction)
        }
        .frame(minWidth: 200, maxWidth: .infinity)
    }
    
    private func add_item()
    {
        element.links.append(MoverLink(from: 0, to: 0))
    }
    
    private func delete_item(_ output: MoverLink)
    {
        if let index = element.links.firstIndex(where: { $0.id == output.id })
        {
            element.links.remove(at: index)
        }
    }
    
    private func binding_for_link(_ link: Binding<MoverLink>) -> Binding<[Int]>
    {
        Binding<[Int]>(
            get:
                {
                    [link.wrappedValue.from, link.wrappedValue.to]
                },
            set:
                { newValue in
                    guard newValue.count >= 2 else { return }
                    
                    link.wrappedValue.from = newValue[0]
                    link.wrappedValue.to   = newValue[1]
                    
                    element.objectWillChange.send()
                    on_update()
                }
        )
    }
}

public struct WriterElementView: View
{
    @ObservedObject var element: WriterModifierElement
    
    @ObservedObject var workspace: Workspace
    
    private let on_update: () -> ()
    
    public init(
        element: WriterModifierElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            let outputs = Binding(
                get: { element.inputs },
                set:
                    { new_value in
                        element.inputs = new_value
                        
                        on_update()
                    }
            )
            
            if outputs.count > 0
            {
                List
                {
                    ForEach($element.inputs)
                    { $input in
                        HStack
                        {
                            let output_to = binding_for_single($input.to)
                            let output_value = Binding(
                                get: { $input.value.wrappedValue },
                                set: {
                                    $input.value.wrappedValue = $0
                                    
                                    on_update()
                                }
                            )
                            
                            Text("Write")
                            TextField("0", value: output_value, format: .number)
                            #if !os(macOS)
                                .keyboardType(.decimalPad)
                            #endif
                            #if os(macOS)
                            Stepper("Enter", value: output_value, in: 0...10000)
                                .labelsHidden()
                            #endif
                            
                            RegistersSelector(
                                text: "to \($input.to.wrappedValue)",
                                registers_count: workspace.registers.count,
                                colors: default_register_colors,
                                indices: output_to,
                                names: ["To"]
                            )
                            #if os(macOS)
                            .frame(width: 64)
                            #elseif os(iOS)
                            .frame(width: 64)
                            #elseif os(visionOS)
                            .frame(width: 96)
                            #endif
                        }
                        .listRowSeparator(.hidden)
                        .contextMenu
                        {
                            Button(role: .destructive)
                            {
                                delete_item($input.wrappedValue)
                            }
                            label:
                            {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        #if os(iOS)
                        .frame(height: 2)
                        #endif
                        #if os(visionOS)
                        .listRowInsets(EdgeInsets(top: 16, leading: -10, bottom: 0, trailing: -10))
                        #endif
                    }
                    .onDelete
                    { offsets in
                        element.inputs.remove(atOffsets: offsets)
                    }
                }
                .frame(minHeight: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            else
            {
                ZStack
                {
                    #if !os(visionOS)
                    Rectangle()
                        .foregroundStyle(.white)
                    #endif
                    
                    Text("No values to write")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            
            Button(action: add_item)
            {
                Text("Add")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            #if os(iOS)
            .buttonBorderShape(.roundedRectangle)
            #endif
            .keyboardShortcut(.defaultAction)
        }
        .frame(minWidth: 200, maxWidth: .infinity)
    }
    
    private func add_item()
    {
        element.inputs.append(WriterInput(value: 0, to: 0))
    }
    
    private func delete_item(_ output: WriterInput)
    {
        if let index = element.inputs.firstIndex(where: { $0.id == output.id })
        {
            element.inputs.remove(at: index)
        }
    }
    
    private func binding_for_single(_ value: Binding<Int>) -> Binding<[Int]>
    {
        Binding(
            get: { [value.wrappedValue] },
            set:
                { new_value in
                    if let first = new_value.first
                    {
                        value.wrappedValue = first
                        on_update()
                    }
                }
        )
    }
}

public struct MathElementView: View
{
    @ObservedObject var element: MathModifierElement
    
    @ObservedObject var workspace: Workspace
    
    private let on_update: () -> ()
    
    @State private var picker_is_presented = false
    
    public init(
        element: MathModifierElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
    }
    
    public var body: some View
    {
        HStack(spacing: 0)
        {
            let expression = Binding(
                get: { element.expression },
                set:
                    { new_value in
                        element.expression = new_value
                    }
            )
            
            let to_index = Binding(
                get: { [element.to_index] },
                set:
                    { new_value in
                        //element.to_index = new_value[0]
                        if let first = new_value.first
                        {
                            element.to_index = first
                            on_update()
                        }
                    }
            )
            
            TextField("Expression", text: expression)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .padding(.trailing, 10)
            #else
                .padding(.trailing)
            #endif
                .onSubmit(on_update)
                .frame(minWidth: 160, maxWidth: .infinity)
            
            RegistersSelector(text: "to \(element.to_index)", registers_count: workspace.registers.count, colors: default_register_colors, indices: to_index, names: ["To"])
            #if os(macOS)
                .frame(width: 64)
            #elseif os(iOS)
                .frame(width: 80)
            #elseif os(visionOS)
                .frame(width: 96)
            #endif
        }
    }
}

public struct ChangerElementView: View
{
    @ObservedObject var element: ChangerModifierElement
    
    @ObservedObject var workspace: Workspace
    
    let on_update: () -> ()
    
    public init(
        element: ChangerModifierElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
        
        if Changer.internal_modules_list.count > 0 && element.module_name == "???"
        {
            element.module_name = Changer.internal_modules_list[0]
        }
    }
    
    public var body: some View
    {
        // MARK: Changer subview
        let module_name = Binding(
            get: { element.module_name },
            set:
                { new_value in
                    element.module_name = new_value
                    
                    on_update()
                }
        )
        
        #if os(macOS)
        HStack
        {
            Picker("Module", selection: module_name) // Changer module picker
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
            .frame(minWidth: 160, maxWidth: .infinity)
            .disabled(Changer.internal_modules_list.count == 0 && Changer.external_modules_list.count == 0)
        }
        #else
        VStack
        {
            Picker("Module", selection: module_name) // Changer module picker
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
            .disabled(Changer.internal_modules_list.count == 0 && Changer.external_modules_list.count == 0)
            .buttonStyle(.bordered)
        }
        #endif
    }
}

public struct ObserverElementView: View
{
    @ObservedObject var element: ObserverModifierElement
    
    @ObservedObject var workspace: Workspace
    
    let on_update: () -> ()
    
    @State private var viewed_object: ProductionObject?
    
    public init(
        element: ObserverModifierElement,
        workspace: Workspace,
        on_update: @escaping () -> () = {}
    )
    {
        self.element = element
        
        self.workspace = workspace
        
        self.on_update = on_update
        
        if self.element.object_name == ""
        {
            self.element.object_name = self.workspace.placed_robot_names.first ?? "???"
            
            switch self.element.object_type
            {
            case .robot:
                element.object_name = workspace.placed_robot_names.first ?? "New Robot"
            case .tool:
                element.object_name = workspace.placed_tool_names.first ?? "New Tool"
            }
        }
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            let object_type = Binding(
                get: { element.object_type },
                set:
                    { new_value in
                        element.object_type = new_value
                        
                        switch new_value
                        {
                        case .robot:
                            element.object_name = workspace.placed_robot_names.first ?? "New Robot"
                        case .tool:
                            element.object_name = workspace.placed_tool_names.first ?? "New Tool"
                        }
                        
                        on_update()
                    }
            )
            
            Picker("Type", selection: object_type)
            {
                ForEach(ObserverObjectType.allCases, id: \.self)
                { object_type in
                    Text(object_type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.bottom)
            
            let object_name = Binding(
                get: { element.object_name },
                set:
                    { new_value in
                        element.object_name = new_value
                        
                        on_update()
                    }
            )
            
            let outputs = Binding(
                get: { element.outputs },
                set:
                    { new_value in
                        element.outputs = new_value
                        
                        on_update()
                    }
            )
            
            switch element.object_type
            {
            case .robot:
                if workspace.placed_robot_names.count > 0
                {
                    Picker("Name", selection: object_name) // robot picker
                    {
                        ForEach(workspace.placed_robot_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .disabled(workspace.placed_robot_names.count == 0)
                    .padding(.bottom)
                }
            case .tool:
                if workspace.placed_tool_names.count > 0
                {
                    Picker("Name", selection: object_name) // tool picker
                    {
                        ForEach(workspace.placed_tool_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .disabled(workspace.placed_tool_names.count == 0)
                    .padding(.bottom)
                }
            }
            
            if outputs.count > 0
            {
                List
                {
                    ForEach($element.outputs)
                    { $output in
                        HStack
                        {
                            let output_to = binding_for_single($output.to)
                            let output_from = Binding(
                                get: { $output.from.wrappedValue },
                                set: { $output.from.wrappedValue = $0; on_update() }
                            )

                            Text("From")
                            TextField("0", value: output_from, format: .number)
                            #if !os(macOS)
                                .keyboardType(.decimalPad)
                            #endif
                            #if os(macOS)
                            Stepper("Enter", value: output_from, in: 0...10000)
                                .labelsHidden()
                            #endif

                            RegistersSelector(
                                text: "to \($output.to.wrappedValue)",
                                registers_count: workspace.registers.count,
                                colors: default_register_colors,
                                indices: output_to,
                                names: ["To"]
                            )
                            #if os(macOS)
                            .frame(width: 64)
                            #elseif os(iOS)
                            .frame(width: 80)
                            #elseif os(visionOS)
                            .frame(width: 96)
                            #endif
                        }
                        .listRowSeparator(.hidden)
                        .contextMenu
                        {
                            Button(role: .destructive)
                            {
                                delete_item($output.wrappedValue)
                            }
                            label:
                            {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        #if os(iOS)
                        .frame(height: 2)
                        #endif
                        #if os(visionOS)
                        .listRowInsets(EdgeInsets(top: 16, leading: -10, bottom: 0, trailing: -10))
                        #endif
                    }
                    .onDelete
                    { offsets in
                        element.outputs.remove(atOffsets: offsets)
                    }

                }
                .frame(minHeight: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            else
            {
                ZStack
                {
                    #if !os(visionOS)
                    Rectangle()
                        .foregroundStyle(.white)
                    #endif
                    
                    Text("No items to ouput")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 160)
                .modifier(ListBorderer())
                .padding(.bottom)
            }
            
            Button(action: add_item)
            {
                Text("Add")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            #if os(iOS)
            .buttonBorderShape(.roundedRectangle)
            #endif
            .keyboardShortcut(.defaultAction)
        }
        .frame(minWidth: 200, maxWidth: .infinity)
    }
    
    private func add_item()
    {
        element.outputs.append(ObserverOutput(from: 0, to: 0))
    }
    
    private func delete_item(_ output: ObserverOutput)
    {
        if let index = element.outputs.firstIndex(where: { $0.id == output.id })
        {
            element.outputs.remove(at: index)
        }
    }
    
    private func binding_for_single(_ value: Binding<Int>) -> Binding<[Int]>
    {
        Binding(
            get: { [value.wrappedValue] },
            set:
                { new_value in
                    if let first = new_value.first
                    {
                        value.wrappedValue = first
                        on_update()
                    }
                }
        )
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
                #if !os(visionOS)
                Rectangle()
                    .foregroundStyle(.white)
                #endif
                
                ModifiersView(workspace: workspace)
                    .onAppear
                    {
                        let robot = Robot(name: "6DOF")
                        robot.is_placed = true
                        robot.add_program(PositionProgram(name: "Square"))
                        
                        let tool = Tool(name: "Gripper")
                        tool.is_placed = true
                        tool.add_program(OperationProgram(name: "Bite"))
                        
                        workspace.robots.append(robot)
                        workspace.tools.append(tool)
                        
                        Changer.internal_modules_list.append("Random")
                        Changer.external_modules_list.append("Defaults")
                    }
            }
        }
    }
    
    struct ModifiersView: View
    {
        @ObservedObject var workspace: Workspace
        
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
                    WriterElementView(element: WriterModifierElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                    
                    MoverElementView(element: MoverModifierElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                    
                    ObserverElementView(element: ObserverModifierElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                }
                
                HStack
                {
                    ChangerElementView(element: ChangerModifierElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                    
                    MathElementView(element: MathModifierElement(), workspace: workspace)
                        .modifier(PreviewBorder())
                }
            }
            .padding()
        }
    }
    
    private struct PreviewBorder: ViewModifier
    {
        public func body(content: Content) -> some View
        {
            content
                .frame(width: element_control_width)
                .padding()
                .background(.bar)
            #if !os(visionOS)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8)
            #else
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            #endif
                .padding()
        }
    }
}
