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
    
  private class ChartStruct {
    let chart: LinearChart
    private(set) var hiddenIndicies: Set<Int> = []
    private(set) var trimRange: ClosedRange<CGFloat>
    
    init(chart: LinearChart) {
      self.chart = chart
      self.trimRange = 0.25...0.5
    }
    
    func updateTrimRange(to newRange: ClosedRange<CGFloat>) {
      trimRange = newRange
    }
    
    func toggleHiden(index: Int) {
      if hiddenIndicies.contains(index) {
        hiddenIndicies.remove(index)
      } else {
        hiddenIndicies.insert(index)
      }
    }
  }
  
  private var charts: [ChartStruct]?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    if let charts = TGCAJsonToChartService().parseJson(named: "chart_data"){
      self.charts = charts.map{ChartStruct(chart: $0)}
    } else {
      let alert = UIAlertController(title: "Could not parse JSON", message: nil, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      present(alert, animated: true, completion: nil)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    registerCells()
    applyCurrentTheme()
    title = "Statistics"
    tableView.showsVerticalScrollIndicator = false
    tableView.showsHorizontalScrollIndicator = false
    tableView.canCancelContentTouches = false
    tableView.delaysContentTouches = true
    subscribe()
  }
  
  func registerCells() {
    tableView.register(UINib(nibName: "TGCAButtonTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAButtonTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTableViewCell.defaultReuseId)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chartColumnLabelCell")
  }
  
  deinit {
    unsubscribe()
  }
}

extension TGCAChartDetailViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if let charts = charts {
      return charts.count + 1
    }
    return 0
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let charts = charts {
      if section < charts.count {
        return charts[section].chart.yVectors.count + 1
      }
      return 1
    }
    return 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let charts = charts {
      if indexPath.section < charts.count {
        if indexPath.row == 0 {
          let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseId) as! TGCAChartTableViewCell
          configureChartCell(cell, section: indexPath.section)
          return cell
        } else {
          let cell = tableView.dequeueReusableCell(withIdentifier: "chartColumnLabelCell")!
          configureChartColumnCell(cell, columnIndex: indexPath.row - 1, section: indexPath.section)
          return cell
        }
      }
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: TGCAButtonTableViewCell.defaultReuseId) as! TGCAButtonTableViewCell
    configureButtonCell(cell)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let charts = charts {
      if indexPath.section < charts.count && indexPath.row == 0 {
        return 360.0
      }
    }
    return 44.0
  }
  
  
  func configureChartCell(_ cell: TGCAChartTableViewCell, section: Int) {
    let cv = cell.chartView
    let tcv = cell.thumbnailChartView
    let tv = cell.trimmerView
    
    tv?.onChange = { [weak self] (newRange, event) in
      if event == .Started {
        cv?.isUserInteractionEnabled = false
      } else if event == .Ended {
        cv?.isUserInteractionEnabled = true
      }
      cv?.trimDisplayRange(to: newRange, with: event)
      self?.charts?[section].updateTrimRange(to: newRange)
    }
    
    if let chart = charts?[section] {
      cv?.configure(with: chart.chart, hiddenIndicies: chart.hiddenIndicies)
      tcv?.configure(with: chart.chart, hiddenIndicies: chart.hiddenIndicies)
      tv?.setCurrentRange(chart.trimRange)
    }
    
    
    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.greatestFiniteMagnitude)
    cell.directionalLayoutMargins = .zero
    cell.selectionStyle = .none
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor
  }
  
  func configureChartColumnCell(_ cell: UITableViewCell, columnIndex: Int, section: Int) {
    if let chartMetadata = charts?[section].chart.yVectors[columnIndex].metaData {
      cell.imageView?.image = UIImage.from(color: chartMetadata.color, size: CGSize(width: 12, height: 12))
      cell.textLabel?.text = chartMetadata.name
    }
    cell.imageView?.layer.cornerRadius = 3.0
    cell.imageView?.clipsToBounds = true
    cell.accessoryType = (charts?[section].hiddenIndicies.contains(columnIndex) ?? false) ? .none : .checkmark
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor
    cell.textLabel?.textColor = UIApplication.myDelegate.currentTheme.mainTextColor
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18.0)
    
    cell.selectionStyle = .none
  }
  
  func configureButtonCell(_ cell: TGCAButtonTableViewCell) {
    cell.selectionStyle = .none
    cell.backgroundColor = UIApplication.myDelegate.currentTheme.foregroundColor

    let applyThemeBlock = {
      UIView.performWithoutAnimation {
        let currentThemeId = UIApplication.myDelegate.currentTheme.identifier
        cell.button.setTitle(currentThemeId == ThemeIdentifier.dark ? "Switch to Day Mode" : "Switch to Night Mode", for: .normal)
        cell.button.layoutIfNeeded()
      }
    }
    applyThemeBlock()
    cell.onClickHandler = {
      UIApplication.myDelegate.toggleTheme()
      applyThemeBlock()
    }
  }
  
}

extension TGCAChartDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let charts = charts {
      if section < charts.count {
        return (charts[section].chart.title ?? "Untitled chart").uppercased()
      }
    }
    return nil
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if let charts = charts {
      if section < charts.count {
        return 50.0
      }
    }
    return 0.0
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if charts != nil, indexPath.section < charts!.count, indexPath.row != 0 {
      let yLineIndex = indexPath.row - 1
      charts?[indexPath.section].toggleHiden(index: yLineIndex)
      if let c = tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.section)) as? TGCAChartTableViewCell {
        c.thumbnailChartView.toggleHidden(at: yLineIndex)
        c.chartView.toggleHidden(at: yLineIndex)
      }
      tableView.cellForRow(at: indexPath)?.accessoryType = (charts?[indexPath.section].hiddenIndicies.contains(yLineIndex) ?? false) ? .none : .checkmark
    }
  }

  
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let theme = UIApplication.myDelegate.currentTheme
    if let header = view as? UITableViewHeaderFooterView {
      header.textLabel?.textColor = theme.tableViewFooterHeaderColor
      let clearView = UIView()
      clearView.backgroundColor = .clear
      header.backgroundView = clearView
    }
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
      for i in 0..<tableView.numberOfSections {
        if let header = tableView.headerView(forSection: i) {
          header.textLabel?.textColor = theme.tableViewFooterHeaderColor
        }
      }
      tableView.visibleCells.forEach{
        $0.backgroundColor = theme.foregroundColor
        $0.textLabel?.textColor = theme.mainTextColor
      }
    }
    
    if animated {
      UIView.animate(withDuration: ANIMATION_DURATION) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
  }
  
}
