//
//  File.swift
//  IndustrialKit
//
//  Created by Artem on 07.02.2025.
//

#if os(visionOS)
import Foundation
import SwiftUI

public struct InspectorModifier<InspectorContent: View>: ViewModifier
{
    @Binding var is_presented: Bool
    let inspector_content: () -> InspectorContent
    
    public func body(content: Content) -> some View
    {
        HStack(spacing: 0)
        {
            content
            
            if is_presented
            {
                inspector_content()
                    .background(.regularMaterial)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut, value: is_presented)
            }
        }
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
#endif
