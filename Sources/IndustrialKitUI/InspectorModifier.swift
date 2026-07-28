//
//  File.swift
//  IndustrialKit
//
//  Created by Artem on 07.02.2025.
//

#if os(visionOS)
import Foundation
import SwiftUI
//import RealityKit

public struct InspectorModifier<InspectorContent: View>: ViewModifier
{
    @Binding var is_presented: Bool
    
    let inspector_content: () -> InspectorContent
    
    public func body(content: Content) -> some View
    {
        HStack
        {
            content

            if is_presented
            {
                inspector_content()
                    .background(.thickMaterial)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.move(edge: .trailing))
                    .backgroundExtensionEffect()
            }
        }
        .animation(.easeInOut, value: is_presented)
    }
}

//MARK: - Inspector modifier for visionOS
public extension View
{
    func inspector<InspectorContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder inspectorContent: @escaping () -> InspectorContent
    ) -> some View
    {
        self.modifier(InspectorModifier(is_presented: isPresented, inspector_content: inspectorContent))
    }
}

#Preview(windowStyle: .automatic)
{
    @Previewable @State var inspector_presented = true
    
    ZStack
    {
        Text("View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        /*RealityView
        { content in
            content.add(ModelEntity(
                mesh: .generateBox(size: Float(0.1), cornerRadius: Float(0.01)),
                materials: [SimpleMaterial(color: .cyan, isMetallic: true)]
            ))
        }*/
    }
    .background(alignment: .topLeading)
    {
        Button(action: { inspector_presented.toggle() })
        {
            Image(systemName: "sidebar.right")
        }
        .buttonBorderShape(.circle)
        .padding(32)
    }
    .inspector(isPresented: $inspector_presented)
    {
        Text("Sidebar")
            .frame(width: 320)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 48, topTrailing: 48), style: .continuous))
}
#endif
