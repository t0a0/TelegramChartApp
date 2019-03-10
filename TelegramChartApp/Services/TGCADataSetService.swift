//
//  TGCADataSetService.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCADataSetService {
  
  private typealias ChartData = (dataSet: DataSet, normalizedDataSet: NormalizedDataSet, identifier: String)
  
  private var minimumX: CGFloat = 0
  private var maximumX: CGFloat = 0
  private var minimumY: CGFloat = 0
  private var maximumY: CGFloat = 0
  private var chartDatas = [ChartData]()
  
  init(dataSets: [(dataSet: DataSet, identifier: String)]) {
    updateBoundaryValues(with: dataSets.map{$0.dataSet})
    chartDatas = dataSets.map{ChartData($0.dataSet, calculateNormalizedDataSet(for: $0.dataSet), $0.identifier)}
  }
  
  
  //  func appendDataSet(dataset: DataSet, forId: String) {
  //
  //  }
  
  func normalizedDataSet(for id: String) -> NormalizedDataSet? {
    return chartDatas.filter{$0.identifier.elementsEqual(id)}.first?.normalizedDataSet
  }
  
  func calculateNormalizedDataSet(for dataSet: DataSet) -> NormalizedDataSet {
    //TODO: Divide by zero return 0 or 1
    //TODO: minus x and y ranges
    return NormalizedDataSet(points: dataSet.points.map{
      NormalizedDataSetPoint(
        x: maximumX - minimumX == 0 ? 0 : ($0.x - minimumX)/(maximumX - minimumX),
        y: maximumY - minimumY == 0 ? 0 : ($0.y - minimumY)/(maximumY - minimumY))
    })
  }
  
  private func updateBoundaryValues(with dataSets: [DataSet]) {
    minimumX = dataSets.minX
    maximumX = dataSets.maxX
    minimumY = dataSets.minY
    maximumY = dataSets.maxY
  }
  
}
