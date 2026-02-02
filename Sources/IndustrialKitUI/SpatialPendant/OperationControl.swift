//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

struct OperationControl: View
{
    @ObservedObject var tool: Tool
    
    @StateObject private var current_operation = OperationCode(0)
    
    @State private var is_expanded = false
    @State private var is_central_pressed = false
    
    @Namespace private var pane_glass
    
    var body: some View
    {
        GlassEffectContainer
        {
            HStack(spacing: 0)
            {
                if !is_expanded
                {
                    // Operation Pane
                    HStack(spacing: 0)
                    {
                        VStack
                        {
                            Text(tool.code_info(current_operation.value).name)
                            #if os(macOS)
                                .font(.system(size: 14, design: .rounded))
                            #else
                                .font(.system(size: 16, design: .rounded))
                            #endif
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                            #if os(iOS)
                                .padding(4)
                                .foregroundStyle(.black)
                            #endif
                        }
                    }
                    .background(.clear)
                    .frame(width: 80) //.frame(maxWidth: .infinity)
                    .glassEffect(.regular.interactive(), in: .capsule(style: .continuous))
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
                    #if os(macOS)
                    .padding(.leading, 10)
                    #else
                    .padding(.leading, 16)
                    #endif
                }
                else
                {
                    // Editor
                    VStack(spacing: 0)
                    {
                        HStack
                        {
                            Rectangle()
                                .fill(.clear)
                                .frame(width: 80, height: 80)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                                .opacity(is_expanded ? 1 : 0)
                            //PositionView(position: $robot.pointer_position)
                                //.opacity(is_expanded ? 1 : 0)
                        }
                        .padding(10)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                is_expanded = false
                            }
                        })
                        {
                            Image(systemName: "chevron.compact.down")
                            #if !os(macOS)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                            #endif
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                        .scaleEffect(is_expanded ? 1 : 0.01)
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                    }
                    #if os(macOS)
                    .frame(width: is_expanded ? 280 : 120)
                    #else
                    .frame(width: is_expanded ? 320 : 120)
                    #endif
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "glass", in: pane_glass)
                    .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
                }
                
                Button
                {
                    do
                    {
                        try tool.perform(code: current_operation.value)
                        {
                            //<#code#>
                        }
                    }
                    catch
                    {
                        print(error.localizedDescription)
                    }
                }
                label:
                {
                    Image(systemName:
                            is_valid_symbol(tool.code_info(current_operation.value).symbol) ?
                            tool.code_info(current_operation.value).symbol :
                            "play"
                    )
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .modifier(CircleButtonImageFramer())
                }
                .modifier(CircleButtonGlassBorderer())
                #if os(macOS) || os(iOS)
                .padding(10)
                #else
                .padding(16)
                #endif
            }
            //.frame(width: 200)
            //.border(.gray)
        }
        //.animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
    }
    
    private func is_valid_symbol(_ symbol: String) -> Bool
    {
        #if os(macOS)
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: symbol) != nil
        #endif
    }
}

// MARK: - Previews
struct OperationControl_Previews: PreviewProvider
{
    struct Container: View
    {
        @StateObject var tool = Tool(name: "Gripper")
        
        var body: some View
        {
            VStack(spacing: 0)
            {
                Spacer()
                
                OperationControl(tool: tool)
                    .padding()
            }
            .frame(width: 400, height: 400)
            .onAppear
            {
                tool.codes = [
                    OperationCodeInfo(value: 0, name: "Close", symbol: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill", info: "UwU"),
                    OperationCodeInfo(value: 1, name: "Open", symbol: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill", info: "OwO")
                ]
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}


/*Button
{
    
}
label:
{
    Image(systemName: "info")
        .imageScale(.large)
    #if os(macOS)
        .frame(width: 16, height: 16)
    #else
        .frame(width: 24, height: 24)
    #endif
        .padding(10)
    #if os(iOS)
        .padding(4)
        .foregroundStyle(.black)
    #endif
}
.buttonBorderShape(.circle)
.buttonStyle(.borderless)*/
