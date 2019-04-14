//
//  TGCA3DaysComparisonChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 14/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCA3DaysComparisonChartView: TGCALinearChartView {
  
  override func getChartAnnotationViewConfiguration(for index: Int) -> TGCAChartAnnotationView.AnnotationViewConfiguration {
    let includedIndicies = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    let coloredValues: [TGCAChartAnnotationView.ColoredValue] = includedIndicies.map{
      let yVector = chart.yVectors[$0]
      return TGCAChartAnnotationView.ColoredValue(title: yVector.metaData.name, value: yVector.vector[index], color: yVector.metaData.color)
    }
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: !isUnderlying, mode: .Time, showsLeftColumn: false, coloredValues: coloredValues)
  }
  
}
