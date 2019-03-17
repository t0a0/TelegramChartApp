//
//  TGCAChartDetailViewController.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAChartDetailViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  var chart: LinearChart? {
    didSet {
      
    }
  }
  
  var hiddenGrapsIndicies = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    registerCells()
    applyCurrentTheme()
    title = "Statistics"
    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    tableView.showsVerticalScrollIndicator = false
    tableView.showsHorizontalScrollIndicator = false
    tableView.canCancelContentTouches = false
    subscribe()
  }
  
  func registerCells() {
    tableView.register(UINib(nibName: "TGCAButtonTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAButtonTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAChartTrimTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTrimTableViewCell.defaultReuseId)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chartColumnLabelCell")
  }
  
  deinit {
    unsubscribe()
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      tableView.backgroundColor = theme.backgroundColor
      tableView.separatorColor = theme.axisColor
      tableView.tintColor = theme.accentColor
      for section in 0..<tableView.numberOfSections {
        for row in 0..<tableView.numberOfRows(inSection: section) {
          let cell = tableView.cellForRow(at: IndexPath(row: row, section: section))
          cell?.backgroundColor = theme.foregroundColor
          if section == 0 && row >= 2 {
            cell?.textLabel?.textColor = theme.mainTextColor
          }
        }
      }
    }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
  }
  
  var chartCell: TGCAChartTableViewCell? {
    return tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TGCAChartTableViewCell
  }
  
  var chartTrimCell: TGCAChartTrimTableViewCell? {
    return tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TGCAChartTrimTableViewCell
  }
  
}

extension TGCAChartDetailViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      guard let chart = chart else {
        return 0
      }
      return chart.yVectors.count + 2
    default:
      return 1
    }
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let theme = UIApplication.myDelegate.currentTheme
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseId) as! TGCAChartTableViewCell
        cell.chartView.graphLineWidth = 2.0
        cell.chartView.shouldDisplaySupportAxis = true
        if let chart = chart {
          cell.chartView.configure(with: chart)
        }
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
        cell.directionalLayoutMargins = .zero
        cell.selectionStyle = .none
        cell.backgroundColor = theme.foregroundColor
        return cell
      } else if indexPath.row == 1 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTrimTableViewCell.defaultReuseId) as! TGCAChartTrimTableViewCell
        cell.chartView.graphLineWidth = 1.0
        if let chart = chart {
          cell.chartView.configure(with: chart)
        }
        cell.trimmerView.delegate = self
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
        cell.directionalLayoutMargins = .zero
        cell.selectionStyle = .none
        cell.backgroundColor = theme.foregroundColor
        return cell
      } else {
        let yLineIndex = indexPath.row - 2
        let cell = tableView.dequeueReusableCell(withIdentifier: "chartColumnLabelCell")!
        cell.selectionStyle = .none
        //TODO: FIX LABEL POSITION
        if let chart = chart {
          cell.imageView?.image = UIImage.from(color: chart.yVectors[yLineIndex].metaData.color, size: CGSize(width: 12, height: 12))
        }
        cell.imageView?.layer.cornerRadius = 3.0
        cell.imageView?.clipsToBounds = true
        cell.textLabel?.text = chart?.yVectors[yLineIndex].metaData.name
        cell.accessoryType = hiddenGrapsIndicies.contains(yLineIndex) ? .none : .checkmark
        cell.backgroundColor = theme.foregroundColor
        cell.textLabel?.textColor = theme.mainTextColor
        return cell
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: TGCAButtonTableViewCell.defaultReuseId) as! TGCAButtonTableViewCell
      cell.selectionStyle = .none
      let currentThemeId = UIApplication.myDelegate.currentTheme.identifier
      UIView.performWithoutAnimation {
        cell.button.setTitle(currentThemeId == ThemeIdentifier.dark ? "Switch to Day Mode" : "Switch to Night Mode", for: .normal)
        cell.button.layoutIfNeeded()
      }
      cell.onClickHandler = {
        UIApplication.myDelegate.toggleTheme()
        let currentThemeId = UIApplication.myDelegate.currentTheme.identifier
        UIView.performWithoutAnimation {
          cell.button.setTitle(currentThemeId == ThemeIdentifier.dark ? "Switch to Day Mode" : "Switch to Night Mode", for: .normal)
          cell.button.layoutIfNeeded()
        }
      }
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        return 300.0
      } else if indexPath.row == 1 {
        return 60.0
      }
    }
    return 44.0
  }
  
}

extension TGCAChartDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? chart?.title ?? "Untitled chart" : nil
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0, indexPath.row > 1 {
      let yLineIndex = indexPath.row - 2
      if let idx = hiddenGrapsIndicies.firstIndex(of: yLineIndex) {
        hiddenGrapsIndicies.remove(at: idx)
      } else {
        hiddenGrapsIndicies.append(yLineIndex)
      }
      chartCell?.chartView.hide(at: yLineIndex)
      chartTrimCell?.chartView.hide(at: yLineIndex)
      tableView.cellForRow(at: indexPath)?.accessoryType = hiddenGrapsIndicies.contains(yLineIndex) ? .none : .checkmark
    }
  }
}

extension TGCAChartDetailViewController: TGCATrimmerViewDelegate {
  
  func trimmerView(_ trimmerView: TGCATrimmerView, didChangeDisplayRange range: ClosedRange<CGFloat>) {
    chartCell?.chartView.updateDisplayRange(with: range)
  }
  
  func trimmerViewDidEndDragging(_ trimmerView: TGCATrimmerView) {
    chartCell?.chartView.isUserInteractionEnabled = true
  }
  
  func trimmerViewDidBeginDragging(_ trimmerView: TGCATrimmerView) {
    chartCell?.chartView.isUserInteractionEnabled = false
  }
  
}

extension TGCAChartDetailViewController: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
}
