//
//  ProgramViews.swift
//  IndustrialKit
//
//  Created by Artem on 15.02.2024.
//

#if os(visionOS)
import SwiftUI
import IndustrialKit
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
                        ProgramElementCard(element)
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
    
    func remove_elements(at offsets: IndexSet) // Remove program element function
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
            ProgramElementCard(element)
                .onTapGesture
            {
                element_view_presented = true
            }
            
            if !is_deliting && !(element is CleanerModifierElement)
            {
                Rectangle()
                    .foregroundStyle(.clear)
                    .sheet(isPresented: $element_view_presented)
                    {
                        ElementView(element: $element, on_update: update_program_element)
                            .modifier(SheetCaption(is_presented: $element_view_presented))
                        /*VStack(spacing: 0)
                        {
                            Spacer(minLength: 72)
                            
                            ElementView(element: $element, on_update: update_program_element)
                        }
                        .modifier(ViewCloseButton(is_presented: $element_view_presented))*/
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
    
    // MARK: Program elements manage functions
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

// MARK: - Previews
#Preview
{
    RobotProgramView()
}

#Preview
{
    ToolProgramView(tool: .constant(Tool()))
}
#endif
