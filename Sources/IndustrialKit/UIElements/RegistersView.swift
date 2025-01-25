//
//  RegistersView.swift
//  IndustrialKit
//
//  Created by Artem on 16.12.2023.
//

import SwiftUI

public struct RegistersView: View
{
    @Binding var registers: [Float]
    
    public let colors: [Color]
    
    private let numbers: [Int]
    
    private let bottom_spacing: CGFloat
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: register_card_maximum, maximum: register_card_maximum), spacing: 0)]
    
    public init(registers: Binding<[Float]>, colors: [Color], bottom_spacing: CGFloat = 0)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = colors
        
        self.bottom_spacing = bottom_spacing
    }
    
    public init(registers: Binding<[Float]>)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = [Color](repeating: .accentColor, count: numbers.count)
        
        self.bottom_spacing = 0
    }
    
    public var body: some View
    {
        ScrollView
        {
            LazyVGrid(columns: columns, spacing: register_card_spacing)
            {
                ForEach(numbers, id: \.self)
                { number in
                    let color_index = number % colors.count
                    
                    if number < registers.count
                    {
                        RegisterCardView(value: $registers[number], number: number, color: colors[color_index])
                            .id(number)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                
                if bottom_spacing > 0
                {
                    Spacer(minLength: bottom_spacing)
                }
            }
            .padding()
            #if os(macOS)
            .padding(.vertical, 10)
            #else
            .padding(.vertical)
            #endif
        }
    }
}

public struct RegistersSelector: View
{
    let text: String
    let registers_count: Int
    let colors: [Color]
    
    @Binding var indices: [Int]
    @State var names: [String]
    
    @State private var is_presented = false
    
    public init(text: String, registers_count: Int, colors: [Color], indices: Binding<[Int]>, names: [String])
    {
        self.text = text
        self.registers_count = registers_count
        self.colors = colors
        
        self._indices = indices
        self.names = names
    }
    
    public init(text: String, registers_count: Int, indices: Binding<[Int]>, names: [String])
    {
        self.text = text
        self.registers_count = registers_count
        self.colors = [Color](repeating: .accentColor, count: registers_count)
        
        self._indices = indices
        self.names = names
    }
    
    public var body: some View
    {
        Button("\(text)", action: { is_presented = true })
            .popover(isPresented: $is_presented)
            {
                RegistersSelectorView(registers_count: registers_count, colors: colors, indices: $indices, names: names)
            }
    }
}

private struct RegistersSelectorView: View
{
    private let registers_count: [Int]
    private let colors: [Color]
    
    @Binding var indices: [Int]
    @State var names: [String]
    
    @State private var current_parameter = 0
    @State private var selections: [Bool]
    @State private var texts: [String]
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 70, maximum: 70), spacing: 0)]
    
    init(registers_count: Int, colors: [Color], indices: Binding<[Int]>, names: [String])
    {
        self.registers_count = (0...registers_count - 1).map { $0 }
        self.colors = colors
        
        self.selections = [Bool](repeating: false, count: registers_count)
        self.texts = [String](repeating: String(), count: registers_count)
        
        self._indices = indices
        self.names = names
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if names.count > 1
            {
                Picker(selection: .constant(1), label: Text("placeholder")) { }
                .padding()
                .hidden()
            }
            
            ScrollView
            {
                LazyVGrid(columns: columns, spacing: 6)
                {
                    ForEach(registers_count, id: \.self)
                    { number in
                        let color_index = number % colors.count
                        
                        RegistersSelectorCardView(is_selected: $selections[number], number: number, color: colors[color_index], selection_text: texts[number])
                        .onTapGesture
                        {
                            select_index(number)
                        }
                    }
                }
                .padding()
                #if os(macOS)
                .padding(.vertical, 10)
                #else
                .padding(.vertical)
                #endif
            }
        }
        .frame(width: 256, height: 256)
        .overlay(alignment: .top)
        {
            if names.count > 1
            {
                Picker("Parameters", selection: $current_parameter)
                {
                    ForEach(Array(indices.enumerated()), id: \.offset)
                    { index, _ in
                        Text("\(names[index])")
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()
                .background(.thinMaterial)
            }
        }
        .onAppear
        {
            update_selections()
            update_texts()
        }
    }
    
    private func update_selections()
    {
        selections = [Bool](repeating: false, count: selections.count)
        
        for index in indices
        {
            if index < selections.count
            {
                selections[index] = true
            }
            else
            {
                selections[selections.count - 1] = true
            }
        }
    }
    
    private func update_texts()
    {
        texts = [String](repeating: String(), count: texts.count)
        
        for (index, value) in indices.enumerated()
        {
            if value < texts.count
            {
                texts[value] += "\(names[index]) "
            }
            else
            {
                texts[texts.count - 1] += "\(names[index]) "
            }
        }
        
        for index in texts.indices
        {
            texts[index] = String(texts[index].dropLast())
        }
    }
    
    private func select_index(_ number: Int)
    {
        indices[current_parameter] = number
        
        update_selections()
        update_texts()
    }
}

private struct RegistersSelectorCardView: View
{
    @Binding var is_selected: Bool
    
    let number: Int
    let color: Color
    
    let selection_text: String
    
    init(is_selected: Binding<Bool>, number: Int, color: Color, selection_text: String)
    {
        self._is_selected = is_selected
        
        self.number = number
        self.color = color
        
        self.selection_text = selection_text
    }
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundStyle(Color(color).opacity(0.75))
            
            Text("\(number)")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(8)
            
            if is_selected
            {
                ZStack
                {
                    Text(selection_text)
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .padding(8)
                        //.lineLimit(1)
                }
                .frame(width: 64, height: 64)
                .background(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .frame(width: 64, height: 64)
        #if !os(visionOS)
        .shadow(radius: 2)
        #else
        .frame(depth: 4)
        #endif
    }
}

//MARK: - Registers data view
public struct RegistersDataView: View
{
    @Binding var is_presented: Bool
    
    @State private var is_registers_count_presented = false
    
    @EnvironmentObject var workspace: Workspace
    
    let save_registers: () -> ()
    
    public init(is_presented: Binding<Bool>, save_registers: @escaping () -> Void = {})
    {
        self._is_presented = is_presented
        self.save_registers = save_registers
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            RegistersView(registers: $workspace.registers, colors: registers_colors, bottom_spacing: 40)
                .overlay(alignment: .bottom)
                {
                    HStack(spacing: 0)
                    {
                        Button(role: .destructive, action: clear_registers)
                        {
                            Image(systemName: "eraser")
                                .padding()
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        
                        Divider()
                        
                        Button(action: save_registers)
                        {
                            Image(systemName: "arrow.down.doc")
                                .padding()
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        
                        Divider()
                        
                        Button(action: { is_registers_count_presented = true })
                        {
                            Image(systemName: "square.grid.2x2")
                                .padding()
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $is_registers_count_presented, arrowEdge: default_popover_edge)
                        {
                            RegistersCountView(is_presented: $is_registers_count_presented, registers_count: workspace.registers.count)
                            #if os(iOS)
                            .presentationDetents([.height(96)])
                            #endif
                        }
                    }
                    .background(.bar)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(radius: 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                }
        }
        .controlSize(.large)
        .modifier(SheetCaption(is_presented: $is_presented, label: "Registers"))
    }
    
    private func clear_registers()
    {
        workspace.clear_registers()
    }
    
    /*private func save_registers()
    {
        controller.registers_document_data_update.toggle()
    }*/
    
    private func update_registers_count()
    {
        workspace.update_registers_count(Workspace.default_registers_count)
    }
    
    #if os(macOS)
    let default_popover_edge: Edge = .top
    #else
    let default_popover_edge: Edge = .bottom
    #endif
}

private struct RegistersCountView: View
{
    @Binding var is_presented: Bool
    @State var registers_count: Int
    
    @EnvironmentObject var workspace: Workspace
    
    //let additive_func: () -> ()
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    registers_count = Workspace.default_registers_count
                    update_count()
                }
            })
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 8)
            #endif
            
            TextField("\(Workspace.default_registers_count)", value: $registers_count, format: .number)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    update_count()
                    //additive_func()
                }
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
            #endif
            
            Stepper("Enter", value: $registers_count, in: 1...1000)
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        /*.onChange(of: registers_count)
        { _, _ in
            update_count()
            additive_func()
        }*/
        .padding(8)
        .controlSize(.regular)
    }
    
    private func update_count()
    {
        if registers_count > 0
        {
            workspace.update_registers_count(registers_count)
        }
    }
}

#if os(macOS)
let register_card_scale: CGFloat = 80
let register_card_spacing: CGFloat = 16
let register_card_font_size: CGFloat = 20
#else
let register_card_scale: CGFloat = 112
let register_card_spacing: CGFloat = 20
let register_card_font_size: CGFloat = 32
#endif

let register_card_maximum = register_card_scale + register_card_spacing

//MARK: - Previews
struct RegistersSelectors_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        @State var registers = [Float](repeating: 0, count: 16)
        
        @State var index = [0]
        @State var indices = [0, 0, 0]
        
        var body: some View
        {
            RegistersView_Previews(registers: $registers)
            RegistersSelectors_Previews(index: $index, indices: $indices)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct RegistersView_Previews: View
    {
        @Binding var registers: [Float]
        
        var body: some View
        {
            RegistersView(registers: $registers, colors: colors_by_seed(seed: 5433))
            #if !os(visionOS)
                .frame(width: 420, height: 420)
                .background(.white)
            #else
                .frame(width: 600, height: 600)
            #endif
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
    }
    
    struct RegistersSelectors_Previews: View
    {
        @Binding var index: [Int]
        @Binding var indices: [Int]
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                RegistersSelector(text: "Value of \(index[0])", registers_count: 12, colors: colors_by_seed(seed: 5433), indices: $index, names: ["Value"])
                    .padding([.horizontal, .top])
                
                RegistersSelector(text: "Location of X: \(indices[0]), Y: \(indices[1]), Z: \(indices[2])", registers_count: 12, colors: colors_by_seed(seed: 5433), indices: $indices, names: ["X", "Y", "Z"])
                    .padding()
            }
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
    }
}
