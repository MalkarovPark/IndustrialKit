//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 16.12.2023.
//

import SwiftUI

public struct RegistersView: View
{
    @Binding var registers: [Float]
    
    public let colors: [Color]
    
    private let numbers: [Int]
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: register_card_maximum, maximum: register_card_maximum), spacing: 0)]
    
    public init(registers: Binding<[Float]>, colors: [Color])
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = colors
    }
    
    public init(registers: Binding<[Float]>)
    {
        self._registers = registers
        self.numbers = (0...registers.count - 1).map { $0 }
        
        self.colors = [Color](repeating: .accentColor, count: numbers.count)
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
                    
                    RegisterCardView(value: $registers[number], number: number, color: colors[color_index])
                        .id(number)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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

struct RegistersSelectorView: View
{
    let registers_count: [Int]
    let colors: [Color]
    
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
    
    var body: some View
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
            selections[index] = true
        }
    }
    
    private func update_texts()
    {
        texts = [String](repeating: String(), count: texts.count)
        
        for (index, value) in indices.enumerated()
        {
            texts[value] += "\(names[index]) "
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

struct RegistersSelectorCardView: View
{
    @Binding var is_selected: Bool
    
    let number: Int
    let color: Color
    
    let selection_text: String
    
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
        .shadow(radius: 2)
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

struct RegistersSelectors_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        @State var registers = [Float](repeating: 0, count: 256)
        
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
                .frame(width: 420, height: 420)
                .background(.white)
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
