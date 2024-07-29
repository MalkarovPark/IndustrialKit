//
//  StateView.swift
//  IndustrialKit
//
//  Created by Artem on 22.12.2022.
//

import SwiftUI

public struct StateView: View
{
    @Binding public var states_data: [StateItem]?
    
    public init(states_data: Binding<[StateItem]?>)
    {
        self._states_data = states_data
    }
    
    public var body: some View
    {
        VStack(spacing: 0)
        {
            if states_data != nil
            {
                Text("Statistics")
                    .font(.title2)
                    .padding()
                
                List(states_data!, children: \.children)
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
        @State var states_data: [StateItem]? = [StateItem]()
        
        var body: some View
        {
            StateView(states_data: $states_data)
                .frame(width: 320, height: 240)
                .onAppear
                {
                    states_data?.append(StateItem(name: "Temperature", value: "+10º", image: "thermometer"))
                    states_data?[0].children = [StateItem(name: "Еngine", value: "+50º", image: "thermometer.transmission"),
                                         StateItem(name: "Fridge", value: "-40º", image: "thermometer.snowflake.circle")]
                    
                    states_data?.append(StateItem(name: "Speed", value: "70 mm/sec", image: "windshield.front.and.wiper.intermittent"))
                }
        }
    }
}
