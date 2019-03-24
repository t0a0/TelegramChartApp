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
  
  weak var sectionheaderView: TGCATableViewSupplementView?
  
  weak var chartCell: TGCAChartTableViewCell?
  weak var chartTrimCell: TGCAChartTrimTableViewCell?
  
  var chart: LinearChart? {
    didSet {
      tableView?.reloadData()
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
    tableView.delaysContentTouches = true
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
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseId) as! TGCAChartTableViewCell
        configureChartCell(cell)
        chartCell = cell
        return cell
      } else if indexPath.row == 1 {
        let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTrimTableViewCell.defaultReuseId) as! TGCAChartTrimTableViewCell
        configureChartTrimCell(cell)
        chartTrimCell = cell
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chartColumnLabelCell")!
        configureChartColumnCell(cell, columnIndex: indexPath.row - 2)
        return cell
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: TGCAButtonTableViewCell.defaultReuseId) as! TGCAButtonTableViewCell
      configureButtonCell(cell)
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
  
  func configureChartCell(_ cell: TGCAChartTableViewCell) {
    cell.chartView.graphLineWidth = 2.0
    cell.chartView.shouldDisplayAxesAndLabels = true
    if let chart = chart {
      cell.chartView.configure(with: chart)
    }
    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
    cell.directionalLayoutMargins = .zero
    cell.selectionStyle = .none
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor
  }
  
  func configureChartTrimCell(_ cell: TGCAChartTrimTableViewCell) {
    cell.chartView.graphLineWidth = 1.0
    cell.chartView.animatesPositionOnHide = false
    cell.chartView.valuesStartFromZero = false
    cell.chartView.canShowAnnotations = false
    cell.chartView.isUserInteractionEnabled = false
    if let chart = chart {
      cell.chartView.configure(with: chart)
    }
    cell.trimmerView.delegate = self
    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
    cell.directionalLayoutMargins = .zero
    cell.selectionStyle = .none
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor
  }
  
  func configureChartColumnCell(_ cell: UITableViewCell, columnIndex: Int) {
    cell.selectionStyle = .none
    if let chart = chart {
      cell.imageView?.image = UIImage.from(color: chart.yVectors[columnIndex].metaData.color, size: CGSize(width: 12, height: 12))
    }
    cell.imageView?.layer.cornerRadius = 3.0
    cell.imageView?.clipsToBounds = true
    cell.textLabel?.text = chart?.yVectors[columnIndex].metaData.name
    cell.accessoryType = hiddenGrapsIndicies.contains(columnIndex) ? .none : .checkmark
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor
    cell.textLabel?.textColor = UIApplication.myDelegate.currentTheme.mainTextColor
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18.0)
  }
  
  func configureButtonCell(_ cell: TGCAButtonTableViewCell) {
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
  }
  
}

extension TGCAChartDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 0 {
      let v = TGCATableViewSupplementView(frame: CGRect.zero)
      v.topLabel.isHidden = true
      v.bottomLabel.textColor = UIApplication.myDelegate.currentTheme.tableViewFooterHeaderColor
      v.bottomLabel.text = (chart?.title ?? "Untitled chart").uppercased()
      sectionheaderView = v
      return v
    } else {
      return nil
    }
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return section == 0 ? 50.0 : 0.0
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0, indexPath.row > 1 {
      let yLineIndex = indexPath.row - 2
      if let idx = hiddenGrapsIndicies.firstIndex(of: yLineIndex) {
        hiddenGrapsIndicies.remove(at: idx)
      } else {
        hiddenGrapsIndicies.append(yLineIndex)
      }
      chartCell?.chartView.toggleHidden(at: yLineIndex)
      chartTrimCell?.chartView.toggleHidden(at: yLineIndex)
      tableView.cellForRow(at: indexPath)?.accessoryType = hiddenGrapsIndicies.contains(yLineIndex) ? .none : .checkmark
    }
  }
}

extension TGCAChartDetailViewController: TGCATrimmerViewDelegate {
  
  func trimmerView(_ trimmerView: TGCATrimmerView, didChangeDisplayRange range: ClosedRange<CGFloat>, event: DisplayRangeChangeEvent) {
    if event == .Started {
      chartCell?.chartView.isUserInteractionEnabled = false
    } else if event == .Ended {
      chartCell?.chartView.isUserInteractionEnabled = false
    }
    chartCell?.chartView.trimDisplayRange(to: range, with: event)
  }
}

extension TGCAChartDetailViewController: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      tableView.backgroundColor = theme.backgroundColor
      tableView.separatorColor = theme.axisColor
      tableView.tintColor = theme.accentColor
      sectionheaderView?.bottomLabel.textColor = theme.tableViewFooterHeaderColor
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
  
}
