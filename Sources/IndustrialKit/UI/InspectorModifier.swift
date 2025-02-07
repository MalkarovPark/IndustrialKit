//
//  File.swift
//  IndustrialKit
//
//  Created by Artem on 07.02.2025.
//

#if os(visionOS)
import Foundation

struct InspectorModifier<InspectorContent: View>: ViewModifier
{
    @Binding var isPresented: Bool
    let inspectorContent: () -> InspectorContent

    func body(content: Content) -> some View
    {
        ZStack(alignment: .trailing)
        {
            content

            if isPresented
            {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture
                    {
                        isPresented = false
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: isPresented)
                
                inspectorContent()
                    .background(.bar)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut, value: isPresented)
            }
        }
    }
}
#endif
