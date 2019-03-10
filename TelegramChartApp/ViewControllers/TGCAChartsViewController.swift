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
    
    let normalTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
    let startString = NSMutableAttributedString(string: "Chart: [", attributes: normalTextAttributes)
    for i in 0..<columnIds.count {
      let idStr = NSAttributedString(string: columnIds[i], attributes: normalTextAttributes)
      let nameStr = NSAttributedString(string: names[i], attributes: [NSAttributedString.Key.foregroundColor : colors[i]])
      startString.append(idStr)
      startString.append(NSAttributedString(string: ": ", attributes: normalTextAttributes))
      startString.append(nameStr)
      startString.append(NSAttributedString(string: i == columnIds.count - 1 ? "]" : ", ", attributes: normalTextAttributes))
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
    
  }
  
}
