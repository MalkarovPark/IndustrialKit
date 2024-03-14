//
//  SwiftUIView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI

public struct StateView: View
{
    @Binding public var state_data: [StateItem]?
    
    public init(state_data: Binding<[StateItem]?>)
    {
        self._state_data = state_data
    }
    
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
        #if !os(visionOS)
        .background(.white)
        #endif
    }
}

struct StateItemView: View
{
    var item: StateItem
    
    var body: some View
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
struct StateView_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        var body: some View
        {
            StateView_Previews()
        }
    }
    
    static var previews: some View
    {
        Container()
    }
    
    struct StateView_Previews: View
    {
        @State var chart_data: [WorkspaceObjectChart]? = [WorkspaceObjectChart]()
        @State var state_data: [StateItem]? = [StateItem]()
        
        var body: some View
        {
            StateView(state_data: $state_data)
                .frame(width: 320, height: 240)
                .onAppear
                {
                    state_data?.append(StateItem(name: "Temperature", value: "+10º", image: "thermometer"))
                    state_data?[0].children = [StateItem(name: "Еngine", value: "+50º", image: "thermometer.transmission"),
                                         StateItem(name: "Fridge", value: "-40º", image: "thermometer.snowflake.circle")]
                    
                    state_data?.append(StateItem(name: "Speed", value: "70 mm/sec", image: "windshield.front.and.wiper.intermittent"))
                }
        }
    }
}
