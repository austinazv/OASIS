//
//  OASISWidgetBundle.swift
//  OASISWidget
//
//  Created by Austin Zambito-Valente on 7/3/26.
//

import WidgetKit
import SwiftUI

@main
struct OASISWidgetBundle: WidgetBundle {
    var body: some Widget {
        OASISWidget()
//        OASISWidgetControl()
        OASISWidgetLiveActivity()
    }
}
