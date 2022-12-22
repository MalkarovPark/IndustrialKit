//
//  SwiftUIView.swift
//  
//
//  Created by Malkarov Park on 22.12.2022.
//

import SwiftUI

public struct StateView: View
{
    @Binding var state_data: [StateItem]?
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if state_data != nil
            {
                Text("Statistics")
                    .font(.title2)
                    .padding()
                
                List(state_data!, children: \.children)
                { item in
                    StateItemView(item: item)
                }
                .listStyle(.plain)
                .padding([.horizontal, .bottom])
            }
            else
            {
                Text("Statistics")
                    .font(.title2)
                    .padding([.horizontal, .top])
                
                EmptyView()
            }
        }
    }
}

public struct StateItemView: View
{
    var item: StateItem
    
    public var body: some View
    {
        HStack
        {
            if item.image != nil
            {
                Image(systemName: item.image ?? "questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.accentColor)
            }
            Text(item.name)
            
            Spacer()
            
            Text(item.value ?? "")
        }
    }
}

//MARK: - Previews
struct StateView_Previews: PreviewProvider
{
    static var previews: some View
    {
        StateView(state_data: .constant([
            StateItem(name: "Temperature", image: "thermometer", children: [StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")])]))
    }
}
