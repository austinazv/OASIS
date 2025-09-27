//
//  SettingsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/19/25.
//

import SwiftUI

struct SettingsPage: View {

    @EnvironmentObject var data: DataSet
    
    @State var festival: festivals = .coachella
    
    var body: some View {
        VStack {
            Form {
//                Section(header: Text("Festival")) {
//                    VStack(alignment: .center) {
//                        Menu {
//                            Picker(selection: $festival, label: Text("")) {
//                                ForEach(festivals.allCases, id: \.self) { option in
//                                    Text(option.rawValue).tag(option)
//                                }
//                            }
//                        } label: {
//                            HStack() {
//                                Text(festival.rawValue)
//                                Image(systemName: "chevron.up.chevron.down")
//                            }
//                        }
//                        Text("OASIS only supports Coachella at this time")
//                            .foregroundStyle(.gray)
//                            .italic()
//                            .padding(.top, 15)
//                    }
//                }
                
                Section(header: Text("Weekend")) {
                    Picker("Weekend", selection: $data.settings.festivalWeekend) {
                        Text("Weekend 1").tag(1)
                        Text("Weekend 2").tag(2)
                        Text("Both").tag(0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Days")) {
                    Toggle(isOn: $data.settings.festivalDays[0], label: { Text("Thursday (Campers Only)") })
                    Toggle(isOn: $data.settings.festivalDays[1], label: { Text("Friday") })
                    Toggle(isOn: $data.settings.festivalDays[2], label: { Text("Saturday") })
                    Toggle(isOn: $data.settings.festivalDays[3], label: { Text("Sunday") })
                }
                
            }
        }
        .navigationTitle("Settings")
        
    }
    
    enum festivals: String, CaseIterable {
        case coachella = "Coachella"
//        case edc = "EDC"
//        case bottlerock = "Bottle Rock"
    }
}

//#Preview {
//    SettingsPage()
//}
