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
  
  let SECTION_HEADER_HEIGHT: CGFloat = 50.0
  let dateRangeFormatter = TGCADateRangeFormatterService()
  let dateToPathComponentsService = TGCADateToPathComponentsService()
  let jsonToChartService = TGCAJsonToChartService()
  
  @IBOutlet weak var tableView: UITableView!
    
  private class ChartStruct {
    let chart: DataChart
    private(set) var hiddenIndicies: Set<Int> = []
    private(set) var trimRange: ClosedRange<CGFloat>
    
    init(chart: DataChart) {
      self.chart = chart
      self.trimRange = 0.0...1.0
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
    
    func hideAll() {
      hiddenIndicies = Set(0..<chart.yVectors.count)
    }
    
    func showAll() {
      hiddenIndicies = []
    }
  }
  
  private var charts: [ChartStruct]?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    var charts = [DataChart]()
    
    for i in 1...5 {
      if let chart = jsonToChartService.parseJson(named: "overview", subDir: "contest/\(i)") {
        charts.append(chart)
      }
    }
    self.charts = charts.map{ChartStruct(chart: $0)}

//    if let charts = TGCAJsonToChartService().parseJson(named: "overview", subDir: "contest/4"){
//    } else {
//      let alert = UIAlertController(title: "Could not parse JSON", message: nil, preferredStyle: .alert)
//      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//      present(alert, animated: true, completion: nil)
//    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.separatorStyle = .none
    registerCells()
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(toggleTheme(_:)))
    applyCurrentTheme()
    title = "Statistics"
    tableView.showsVerticalScrollIndicator = false
    tableView.showsHorizontalScrollIndicator = false
    tableView.canCancelContentTouches = false
    tableView.delaysContentTouches = true
    subscribe()
    
  }
  override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
    if let indexPaths = tableView.indexPathsForVisibleRows {
      tableView.reloadRows(at: indexPaths, with: .none)
    }
  }
  
  override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
    navigationController?.setNavigationBarHidden(toInterfaceOrientation == .landscapeLeft || toInterfaceOrientation == .landscapeRight, animated: true)
  }
  
  func registerCells() {
    tableView.register(UINib(nibName: "TGCALinearChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCALinearChartTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCASingleBarChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCASingleBarChartTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAStackedBarChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAStackedBarChartTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCAPercentageChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAPercentageChartTableViewCell.defaultReuseId)
    tableView.register(UINib(nibName: "TGCALinearChartWith2AxesTableViewCell", bundle: nil), forCellReuseIdentifier: TGCALinearChartWith2AxesTableViewCell.defaultReuseId)

  }
  
  deinit {
    unsubscribe()
  }
  
  @objc func toggleTheme(_ sender: Any?) {
    UIApplication.myDelegate.toggleTheme()
  }
  
  func preloadJSONData(chartIndex: Int, date: Date) -> DataChart? {
    let pc = dateToPathComponentsService .pathComponents(for: date)
    return jsonToChartService.parseJson(named: pc.fileName, subDir: "contest/\(chartIndex+1)/\(pc.folder)")
//    if let chart = jsonToChartService.parseJson(named: pc.fileName, subDir: "contest/\(chartIndex+1)/\(pc.folder)") {
//      print(chart)
//    }
  }
}

extension TGCAChartDetailViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return charts?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: TGCAChartTableViewCell!
    let chartType = charts![indexPath.section].chart.type
    switch chartType {
    case .linear:
      cell = tableView.dequeueReusableCell(withIdentifier: TGCALinearChartTableViewCell.defaultReuseId) as! TGCALinearChartTableViewCell
    case .linearWith2Axes:
      cell = tableView.dequeueReusableCell(withIdentifier: TGCALinearChartWith2AxesTableViewCell.defaultReuseId) as! TGCALinearChartWith2AxesTableViewCell
    case .percentage:
      cell = tableView.dequeueReusableCell(withIdentifier: TGCAPercentageChartTableViewCell.defaultReuseId) as! TGCAPercentageChartTableViewCell
    case .singleBar:
      cell = tableView.dequeueReusableCell(withIdentifier: TGCASingleBarChartTableViewCell.defaultReuseId) as! TGCASingleBarChartTableViewCell
    case .stackedBar:
      cell = tableView.dequeueReusableCell(withIdentifier: TGCAStackedBarChartTableViewCell.defaultReuseId) as! TGCAStackedBarChartTableViewCell
    }
    configureChartCell(cell, section: indexPath.section)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return view.bounds.height
  }
  
  
  func configureChartCell(_ cell: TGCAChartTableViewCell, section: Int) {
    
    if let chart = charts?[section] {
      cell.headerView.label.text = ""

      var b = [TGCAFilterButton]()
      
      for i in 0..<chart.chart.yVectors.count {
        let yV = chart.chart.yVectors[i]
        let button = TGCAFilterButton(type: .system)
        let width = button.configure(checked: true, titleText: yV.metaData.name, color: yV.metaData.color)
        button.frame.size = CGSize(width: width, height: TGCAFilterButton.buttonHeight)
        if chart.hiddenIndicies.contains(i) {
          button.uncheck()
        }
        button.onTap = {
          button.toggleChecked()
          chart.toggleHiden(index: i)
          cell.chartView?.toggleHidden(at: i)
          cell.thumbnailChartView?.toggleHidden(at: i)
        }
        button.onLongTap = {
          if cell.chartFiltersView?.isAnyButtonChecked ?? false {
            cell.chartFiltersView?.uncheckAll()
            cell.chartView?.hideAll()
            cell.thumbnailChartView?.hideAll()
            chart.hideAll()
          } else {
            cell.chartFiltersView?.checkAll()
            cell.chartView?.showAll()
            cell.thumbnailChartView?.showAll()
            chart.showAll()
          }
        }
        b.append(button)
      }
      cell.chartFiltersHeightConstraint.constant = cell.chartFiltersView?.setupButtons(b) ?? 0
      
      cell.chartView?.onRangeChange = {[weak self] left, right in
        guard let left = left else {
          cell.headerView.label.text = ""
          return
        }
        cell.headerView.label.text = self?.dateRangeFormatter.prettyDateStringFrom(left: left, right: right)
      }
      
      cell.chartView?.onAnnotationClick = {[weak self] date in
        if let lul = self?.preloadJSONData(chartIndex: section, date: date) {
          cell.chartView?.configure(with: lul, hiddenIndicies: [], displayRange: chart.trimRange)
          cell.thumbnailChartView?.configure(with: lul, hiddenIndicies: [])
        }
        
      }
      
      cell.chartView?.configure(with: chart.chart, hiddenIndicies: chart.hiddenIndicies, displayRange: chart.trimRange)
      cell.thumbnailChartView?.configure(with: chart.chart, hiddenIndicies: chart.hiddenIndicies)
      cell.trimmerView?.setCurrentRange(chart.trimRange)
      
      cell.trimmerView?.onChange = {(newRange, event) in
        if event == .Started {
          cell.chartView?.isUserInteractionEnabled = false
        } else if event == .Ended {
          cell.chartView?.isUserInteractionEnabled = true
        }
        cell.chartView?.trimDisplayRange(to: newRange, with: event)
        chart.updateTrimRange(to: newRange)
      }
    }
    let theme = UIApplication.myDelegate.currentTheme
    cell.headerView.label.textColor = theme.mainTextColor
    cell.backgroundColor = theme.foregroundColor
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
    return SECTION_HEADER_HEIGHT
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
    navigationItem.rightBarButtonItem?.title = theme.identifier == .dark ? "Day Mode" : "Night mode"

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
