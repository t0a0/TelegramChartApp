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
  
  var charts = [JsonCharts.JsonChart]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Charts"
    if let data = try? Data(contentsOf: Bundle.main.url(forResource: "chart_data", withExtension: "json")!)  {
      do {
        self.charts = try JSONDecoder().decode(JsonCharts.self, from: data).charts
      } catch {
        let alert = UIAlertController(title: "Oops", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
      }
    }
  }
  
  func attributedString(for chart: JsonCharts.JsonChart) -> NSAttributedString {
    let columnIds = chart.yColumns.map{$0.identifier}
    let names = columnIds.map{chart.name(forIdentifier: $0)!}
    let colors = columnIds.map{chart.color(forIdentifier: $0)!}
    
    func astr(_ str: String, color: UIColor = .black) -> NSMutableAttributedString {
      return NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor : color])
    }
    
    let startString = astr("Chart: [")
    for i in 0..<columnIds.count {
      startString.append(astr(columnIds[i]))
      startString.append(astr(": "))
      startString.append(astr(names[i], color: colors[i]))
      startString.append(astr(i == columnIds.count - 1 ? "]" : ", "))
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
    cell.detailTextLabel?.text = "X values count: \(chart.xColumn.values.count)"
    cell.accessoryType = .disclosureIndicator
    return cell
  }
  
}

extension TGCAChartsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vectorService = TGCAVectorNormalizationService(normalizationRange: 0.0...300.0)
    let chart = charts[indexPath.row]
    let yCols = chart.yColumns
    let yVectors = vectorService.normalizeVectors(yCols.map{$0.values})
    
    var normalizedYVectors = [TGCANormalizedChartDataVector]()
    for i in 0..<yCols.count {
      let yCol = yCols[i]
      let nv = TGCANormalizedChartDataVector(vector: yVectors[i], identifier: yCol.identifier, color: chart.color(forIdentifier: yCol.identifier) ?? .black, normalizationRange: vectorService.normalizationRange)
      normalizedYVectors.append(nv)
    }
    let normalizedChart = TGCANormalizedChart(yVectors: normalizedYVectors, xVector: TGCAVectorNormalizationService(normalizationRange: 0.0...375.0).normalizeVector(chart.xColumn.values))
    
    guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TGCAChartDetailViewController") as? TGCAChartDetailViewController else {
      return
    }
    vc.normalizedChart = normalizedChart
    navigationController?.pushViewController(vc, animated: true)
  }
  
}
