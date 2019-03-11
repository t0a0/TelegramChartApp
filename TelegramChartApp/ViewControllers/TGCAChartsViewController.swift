//
//  TGCAChartsViewController.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAChartsViewController: UIViewController {
  let cell_reuseId_chartInfo = "chartInfoCell"
  
  @IBOutlet weak var tableView: UITableView!
  
  var charts = [LinearChart]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Charts"
    guard let charts = TGCAJsonToChartService().parse() else {
      return
    }
    self.charts = charts
  }
  
  func attributedString(for chart: LinearChart) -> NSAttributedString {
    func astr(_ str: String, color: UIColor = .black) -> NSMutableAttributedString {
      return NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor : color])
    }
    
    let startString = astr("Chart: [")
    for i in 0..<chart.yVectors.count {
      let yV = chart.yVectors[i]
      startString.append(astr(yV.metaData.identifier))
      startString.append(astr(": "))
      startString.append(astr(yV.metaData.name, color: yV.metaData.color))
      startString.append(astr(i == chart.yVectors.count - 1 ? "]" : ", "))
    }
    return startString
  }
  
}

extension TGCAChartsViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return charts.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cell_reuseId_chartInfo)!
    let chart = charts[indexPath.row]
    cell.textLabel?.attributedText = attributedString(for: chart)
    cell.detailTextLabel?.text = "X values count: \(chart.xVector.vector.count)"
    cell.accessoryType = .disclosureIndicator
    return cell
  }
  
}

extension TGCAChartsViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let vectorService = TGCAVectorNormalizationService(normalizationRange: 0.0...300.0)
//    let chart = charts[indexPath.row]
//    let yCols = chart.yColumns
//    let yVectors = vectorService.normalizeVectors(yCols.map{$0.values})
//
//    var normalizedYVectors = [TGCANormalizedChartDataVector]()
//    for i in 0..<yCols.count {
//      let yCol = yCols[i]
//      let nv = TGCANormalizedChartDataVector(vector: yVectors[i], identifier: yCol.identifier, color: chart.color(forIdentifier: yCol.identifier) ?? .black, normalizationRange: vectorService.normalizationRange)
//      normalizedYVectors.append(nv)
//    }
//    let normalizedChart = TGCANormalizedChart(yVectors: normalizedYVectors, xVector: TGCAVectorNormalizationService(normalizationRange: 0.0...375.0).normalizeVector(chart.xColumn.values))
//
    guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TGCAChartDetailViewController") as? TGCAChartDetailViewController else {
      return
    }
    vc.chart = charts[indexPath.row]
    navigationController?.pushViewController(vc, animated: true)
  }
  
}
