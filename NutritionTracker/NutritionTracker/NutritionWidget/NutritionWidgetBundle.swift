//
//  NutritionWidgetBundle.swift
//  NutritionWidget
//
//  Created by Tomer Cohen on 01/08/2025.
//

import WidgetKit
import SwiftUI

@main
struct NutritionWidgetBundle: WidgetBundle {
    var body: some Widget {
        NutritionWidget()
        NutritionWidgetControl()
        NutritionWidgetLiveActivity()
    }
}
