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
    guard let charts = TGCAJsonToChartService().parse() else {
      let alert = UIAlertController(title: "Could not parse JSON", message: nil, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      present(alert, animated: true, completion: nil)
      return
    }
    self.charts = charts
    
    applyCurrentTheme()
    subscribe()
    title = "Charts"
  }
  
  deinit {
    unsubscribe()
  }
  
  func attributedString(for chart: LinearChart) -> NSAttributedString {
    func astr(_ str: String, color: UIColor = UIApplication.myDelegate.currentTheme.mainTextColor) -> NSMutableAttributedString {
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
    cell.selectionStyle = .none
    let theme = UIApplication.myDelegate.currentTheme
    cell.detailTextLabel?.textColor = theme.mainTextColor
    cell.backgroundColor = theme.foregroundColor
    return cell
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return "Copyright © 2019 Igor Fedotov. All Rights Reserved."
  }
  
}

extension TGCAChartsViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TGCAChartDetailViewController") as? TGCAChartDetailViewController else {
      return
    }
    vc.chart = charts[indexPath.row]
    navigationController?.pushViewController(vc, animated: true)
  }
  
}


extension TGCAChartsViewController: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
    tableView.reloadData()
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      tableView.backgroundColor = theme.backgroundColor
      tableView.separatorColor = theme.axisColor
      tableView.tintColor = theme.accentColor
    }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
    
  }
}
