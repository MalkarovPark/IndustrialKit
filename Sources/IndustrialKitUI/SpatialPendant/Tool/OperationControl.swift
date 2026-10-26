//
//  OperationControl.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

public struct OperationControl: View
{
    @ObservedObject var tool: Tool
    
    @Binding var is_vertical: Bool
    
    @State private var is_expanded = false
    @State private var is_central_pressed = false
    
    @State private var code_index = 0
    @State private var slide_out: Edge = .top
    @State private var slide_in: Edge = .bottom
    
    @Namespace private var pane_glass
    
    public init(
        tool: Tool,
        is_vertical: Binding<Bool> = .constant(false)
    )
    {
        self.tool = tool
        self._is_vertical = is_vertical
    }
    
    public var body: some View
    {
        DynamicStack(is_vertical: $is_vertical) //HStack(spacing: 12)
        {
            ZStack
            {
                if !is_expanded
                {
                    // Operation Pane
                    ZStack
                    {
                        // Chevron Buttons
                        HStack(spacing: 0)
                        {
                            if tool.codes.count > 0
                            {
                                Button
                                {
                                    move_code(-1)
                                }
                                label:
                                {
                                    Image(systemName: "chevron.left")
                                        .padding(.trailing)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    #if !os(macOS)
                                        .font(.system(size: 14, design: .rounded))
                                    #endif
                                }
                                .buttonStyle(.borderless)
                                #if os(iOS)
                                .tint(.black)
                                #endif
                                .contentShape(Rectangle())
                            }
                            
                            if tool.codes.count > 0
                            {
                                Button
                                {
                                    move_code(1)
                                }
                                label:
                                {
                                    Image(systemName: "chevron.right")
                                        .padding(.leading)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    #if !os(macOS)
                                        .font(.system(size: 14, design: .rounded))
                                    #endif
                                }
                                .buttonStyle(.borderless)
                                #if os(iOS)
                                .tint(.black)
                                #endif
                                .contentShape(Rectangle())
                            }
                        }
                        
                        // Operation Button
                        Button
                        {
                            tool.start_pause_single_operation()
                        }
                        label:
                        {
                            if tool.codes.count > 0
                            {
                                Image(systemName:
                                        is_valid_symbol(current_code_info.symbol_name) ?
                                        current_code_info.symbol_name :
                                        ""
                                )
                                .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                                .modifier(CircleButtonImageFramer())
                            }
                            else
                            {
                                Rectangle()
                                    .fill(.clear)
                                    .modifier(CircleButtonImageFramer())
                            }
                        }
                        .modifier(CircleButtonGlassBorderer())
                        
                        VStack
                        {
                            Text(tool.codes.count > 0 ? tool.code_info(tool.current_operation.value).name : "")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                .padding(10)
                            #if os(iOS)
                                .padding(tool.codes.count > 0 ? 0 : 4)
                                .foregroundStyle(.black)
                            #endif
                                .id(tool.current_operation.value)
                                .transition(.asymmetric(
                                    insertion: .move(edge: slide_in).combined(with: .opacity),
                                    removal: .move(edge: slide_out).combined(with: .opacity)
                                ))
                                .background { Color.clear.contentShape(Rectangle()) }
                            
                            Spacer()
                            
                            let value_binding = Binding(
                                get: { current_code_info.value },
                                set:
                                    { new_value in
                                        tool.current_operation = OperationCode(new_value)
                                    }
                            )
                            
                            TextField("Value", value: value_binding, format: .number)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                .padding(10)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.plain)
                        }
                    }
                    //.background(.clear)
                    .frame(width: 120, height: 120)
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
                        
                        HStack(spacing: 0)
                        {
                            ZStack
                            {
                                let operation_binding = Binding(
                                    get: { current_code_info },
                                    set:
                                        { new_value in
                                            tool.current_operation = OperationCode(new_value.value)
                                        }
                                )
                                
                                Rectangle()
                                    .fill(.clear)
                                
                                #if os(macOS)
                                ScrollView
                                {
                                    Picker("Code", selection: operation_binding)
                                    {
                                        if tool.codes.count > 0
                                        {
                                            ForEach(tool.codes, id:\.self)
                                            { code in
                                                //Text(code.name)
                                                    //.font(.system(size: 12))
                                                HStack
                                                {
                                                    VStack(alignment: .leading)
                                                    {
                                                        Text(code.name)
                                                            .font(.system(size: 12))
                                                        
                                                        if !code.description.isEmpty
                                                        {
                                                            Text(code.description)
                                                                .font(.system(size: 8))
                                                                .lineLimit(1)
                                                                .help(code.description)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                        else
                                        {
                                            Text("None")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .pickerStyle(.radioGroup)
                                    .labelsHidden()
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                }
                                #else
                                Picker("Code", selection: operation_binding)
                                {
                                    if tool.codes.count > 0
                                    {
                                        ForEach(tool.codes, id:\.self)
                                        { code in
                                            //Text(code.name)
                                                //.font(.system(size: 16))
                                            HStack
                                            {
                                                VStack(alignment: .leading)
                                                {
                                                    Text(code.name)
                                                        .font(.system(size: 12))
                                                    
                                                    if !code.description.isEmpty
                                                    {
                                                        Text(code.description)
                                                            .font(.system(size: 8))
                                                            .lineLimit(1)
                                                            .help(code.description)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .pickerStyle(.wheel)
                                .buttonStyle(.borderedProminent)
                                #endif
                            }
                            
                            /*Divider()
                                .padding(.vertical, 4)
                            
                            if !current_code_info.description.isEmpty
                            {
                                ScrollView
                                {
                                    Text(current_code_info.description)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    #if os(macOS)
                                        .font(.system(size: 10))
                                    #else
                                        .font(.system(size: 14))
                                    #endif
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                        .padding(.horizontal, 4)
                                }
                            }
                            else
                            {
                                Text("No Info")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    #if os(macOS)
                                    .font(.system(size: 12))
                                    #else
                                    .font(.system(size: 16))
                                    #endif
                                    .foregroundStyle(.secondary)
                                    .offset(y: -8)
                            }*/
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.0)))
                    .frame(width: is_expanded ? 200 : 120, height: !is_vertical ? 120 : pendant_content_height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(is_central_pressed ? 1.05 : 1)
        }
        .disabled(tool.codes.count == 0)
        #if os(visionOS)
        .offset(z: 2)
        #endif
    }
    
    private func move_code(_ step: Int)
    {
        guard !tool.codes.isEmpty else { return }
        
        if step > 0
        {
            slide_out = .top
            slide_in = .bottom
        }
        else
        {
            slide_out = .bottom
            slide_in = .top
        }
        
        withAnimation(.easeInOut)
        {
            code_index = tool.codes.firstIndex(of: current_code_info) ?? 0
            
            code_index = (code_index + step + tool.codes.count) % tool.codes.count
            tool.current_operation = OperationCode(tool.codes[code_index].value)
        }
    }
    
    private func is_valid_symbol(_ symbol: String) -> Bool
    {
        #if os(macOS)
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: symbol) != nil
        #endif
    }
    
    private var current_code_info: OperationCodeInfo
    {
        return tool.code_info(tool.current_operation.value)
    }
}

private struct ExpandingShape: InsettableShape
{
    var progress: CGFloat
    var inset_amount: CGFloat = 0
    
    var animatableData: AnimatablePair<CGFloat, CGFloat>
    {
        get
        {
            AnimatablePair(progress, inset_amount)
        }
        set
        {
            progress = newValue.first
            inset_amount = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path
    {
        let rect = rect.insetBy(dx: inset_amount, dy: inset_amount)
        let capsule_radius = min(rect.width, rect.height) / 2
        let radius = 16 + (capsule_radius - 16) * (1 - progress)
        
        return RoundedRectangle(
            cornerRadius: radius,
            style: .continuous
        )
        .path(in: rect)
    }
    
    func inset(by amount: CGFloat) -> ExpandingShape
    {
        var copy = self
        copy.inset_amount += amount
        return copy
    }
}

// MARK: - Previews
struct OperationControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var tool = Tool(name: "Gripper")
        @State var is_vertical = false
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                OperationControl(tool: tool, is_vertical: $is_vertical)
                    .padding()
            }
            .frame(width: 400, height: 400)
            .onAppear
            {
                tool.codes = [
                    OperationCodeInfo(value: 0, name: "Close", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", description: "Close the Tool"),
                    OperationCodeInfo(value: 1, name: "Open", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", description: "Open the Tool"),
                    OperationCodeInfo(value: 2, name: "UwU", symbol_name: "questionmark"),
                    OperationCodeInfo(value: 3, name: "OwO UwU WuW", symbol_name: "questionmark", description: "In some concept art, it was revealed that the loot in ancient cities was originally going to be stored within jar-shaped pots")
                ]
            }
            .overlay(alignment: .topLeading)
            {
                Button(is_vertical ? "Vertical" : "Horizontal")
                {
                    is_vertical.toggle()
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
