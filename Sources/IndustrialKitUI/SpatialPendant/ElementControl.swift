//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 02.02.2026.
//

import SwiftUI
import IndustrialKit

struct ElementControl: View
{
    @ObservedObject var workspace: Workspace
    
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
                        VStack(alignment: .leading)
                        {
                            Text(workspace.current_element.title)
                                .font(.title3)
                                .animation(.easeInOut(duration: 0.2), value: workspace.current_element.title)
                            Text(workspace.current_element.info)
                                .foregroundColor(.secondary)
                                .animation(.easeInOut(duration: 0.2), value: workspace.current_element.info)
                        }
                        .padding()
                        
                        /*VStack
                        {
                            Text(workspace.current_element.info)
                            #if os(macOS)
                                .font(.system(size: 14, design: .rounded))
                            #else
                                .font(.system(size: 18, design: .rounded))
                            #endif
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                //.truncationMode(.tail)
                                .padding(10)
                            #if os(iOS)
                                .padding(tool.codes.count > 0 ? 0 : 4)
                                .foregroundStyle(.black)
                            #endif
                        }*/
                    }
                    .background(.clear)
                    .frame(width: 160) //.frame(maxWidth: .infinity)
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
                        .padding(.top, 10)
                        .scaleEffect(is_expanded ? 1 : 0.01)
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: is_expanded)
                        
                        HStack
                        {
                            
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
                    .animation(.spring(response: 0.35, dampingFraction: 0.95), value: is_expanded)
                }
                
                Button
                {
                    print("Finished")
                    /*workspace.perform(workspace.current_element)
                    {
                        print("Finished")
                        /*Task
                        { @MainActor in
                            print("Finished")
                        }*/
                    }*/
                    /*{ result in
                        print(result)
                    }*/
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
                #if !os(visionOS)
                .glassEffect(.regular.interactive().tint(workspace.current_element.color), in: .rect(cornerRadius: 16, style: .continuous))
                #else
                .controlSize(.large)
                .buttonStyle(.borderless)
                .glassBackgroundEffect()
                .frame(depth: 24)
                #endif
                #if os(macOS) || os(iOS)
                .padding(10)
                #else
                .padding(16)
                #endif
            }
        }
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
            .frame(width: 400, height: 400)
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}
