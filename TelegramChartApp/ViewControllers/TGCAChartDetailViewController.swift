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
    
  
  
  private let chartContainers = (1...5).map{TGCAJsonToChartService().parseJson(named: "overview", subDir: "contest/\($0)")!}.map{ChartContainer(chart: $0)}
  
  /*override func awakeFromNib() {
    super.awakeFromNib()

    /*if let charts = TGCAJsonToChartService().parseJson(named: "overview", subDir: "contest/4"){
    } else {
      let alert = UIAlertController(title: "Could not parse JSON", message: nil, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      present(alert, animated: true, completion: nil)
    }*/
  }*/
  
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
  
  override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
    navigationController?.setNavigationBarHidden(toInterfaceOrientation == .landscapeLeft || toInterfaceOrientation == .landscapeRight, animated: true)
  }
  
  var visibleRows: [IndexPath]?
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { context in
      // Save the visible row position
      self.visibleRows = self.tableView.indexPathsForVisibleRows
      context.viewController(forKey: UITransitionContextViewControllerKey.from)
    }, completion: { context in
      // Scroll to the saved position prior to screen rotate
      guard let visibleRow = self.visibleRows?.first else {
        return
      }
      self.tableView.scrollToRow(at: visibleRow, at: .middle, animated: true)
    })
  }
  
  func registerCells() {
    tableView.register(UINib(nibName: "TGCAChartTableViewCell", bundle: nil), forCellReuseIdentifier: TGCAChartTableViewCell.defaultReuseIdd)
  }
  
  deinit {
    unsubscribe()
  }
  
  @objc func toggleTheme(_ sender: Any?) {
    UIApplication.myDelegate.toggleTheme()
  }
  
  func loadZoomedInJSONDataFor(chartIndex: Int, date: Date) -> DataChart? {
    let pc = dateToPathComponentsService .pathComponents(for: date)
    return jsonToChartService.parseJson(named: pc.fileName, subDir: "contest/\(chartIndex+1)/\(pc.folder)")
  }
  
  private func getButtonsConfigurationFor(chartContainer: ChartContainer, cell: TGCAChartTableViewCell, index: Int) -> [TGCAFilterButton] {
    
    var buttons = [TGCAFilterButton]()
    for i in 0..<chartContainer.chart.yVectors.count {
      let yV = chartContainer.chart.yVectors[i]
      
      let button = TGCAFilterButton(type: .system)
      let width = button.configure(checked: true, titleText: yV.metaData.name, color: yV.metaData.color)
      button.frame.size = CGSize(width: width, height: TGCAFilterButton.buttonHeight)
      
      if chartContainer.hiddenIndicies.contains(i) {
        button.uncheck()
      }
      
      button.onTap = {
        button.toggleChecked()
        chartContainer.toggleHiden(index: i)
        cell.chartView?.toggleHidden(at: [i])
        cell.thumbnailChartView?.toggleHidden(at: [i])
      }
      
      button.onLongTap = {
        if cell.chartFiltersView?.isAnyButtonChecked ?? false {
          cell.chartFiltersView?.uncheckAll()
          cell.chartView?.hideAll()
          cell.thumbnailChartView?.hideAll()
          chartContainer.hideAll()
        } else {
          cell.chartFiltersView?.checkAll()
          cell.chartView?.showAll()
          cell.thumbnailChartView?.showAll()
          chartContainer.showAll()
        }
      }
      
      buttons.append(button)
    }
    return buttons
  }
}

extension TGCAChartDetailViewController: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return chartContainers.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: TGCAChartTableViewCell.defaultReuseIdd) as! TGCAChartTableViewCell
    cell.configure(with: chartContainers[indexPath.section])
    configureChartCell(cell, section: indexPath.section)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return view.bounds.height
  }
  
  
  func configureChartCell(_ cell: TGCAChartTableViewCell, section: Int) {
    
    let chartContainer = chartContainers[section]
    
    let translatedBounds = chartContainer.chart.translatedBounds(for: chartContainer.trimRange)
    let left = chartContainer.chart.datesVector[translatedBounds.lowerBound]
    let right = chartContainer.chart.datesVector[translatedBounds.upperBound]
    cell.headerView.label.text = dateRangeFormatter.prettyDateStringFrom(left: left, right: right)
    
    cell.headerView.onZoomOut = { [weak self] in
      chartContainer.underlyingChartContainer = nil
      cell.headerView.zoomOutButton.isHidden = true
      if let buttonsSetup = self?.getButtonsConfigurationFor(chartContainer: chartContainer, cell: cell, index: section) {
        cell.chartFiltersHeightConstraint.constant = cell.chartFiltersView?.setupButtons(buttonsSetup) ?? 0
      }
      cell.chartView.transitionToMainChart()
      cell.thumbnailChartView.transitionToMainChart()
      cell.trimmerView?.setCurrentRange(chartContainer.trimRange, animated: true)
    }
    
    
    cell.chartFiltersHeightConstraint.constant = cell.chartFiltersView?.setupButtons(getButtonsConfigurationFor(chartContainer: chartContainer, cell: cell, index: section)) ?? 0
    
    cell.chartView?.onAnnotationClick = {[weak self] date in
      if let underlyingChart = self?.loadZoomedInJSONDataFor(chartIndex: section, date: date) {
        let newContainer = ChartContainer(chart: underlyingChart, hiddenIndicies: chartContainer.hiddenIndicies)
        chartContainer.underlyingChartContainer = newContainer
        cell.headerView.zoomOutButton.isHidden = false
        if let buttonsSetup = self?.getButtonsConfigurationFor(chartContainer: newContainer, cell: cell, index: section) {
           cell.chartFiltersHeightConstraint.constant = cell.chartFiltersView?.setupButtons(buttonsSetup) ?? 0
        }
       
        
        cell.chartView?.transitionToUnderlyingChart(underlyingChart, displayRange: newContainer.trimRange)
        cell.thumbnailChartView?.transitionToUnderlyingChart(underlyingChart, displayRange: CGFloatRangeInBounds.ZeroToOne)
        cell.trimmerView?.setCurrentRange(newContainer.trimRange, animated: true)
        return true
      }
      return false
    }


    cell.chartView?.configure(with: chartContainer.chart, hiddenIndicies: chartContainer.hiddenIndicies, displayRange: chartContainer.trimRange)
    cell.thumbnailChartView?.configure(with: chartContainer.chart, hiddenIndicies: chartContainer.hiddenIndicies, displayRange: CGFloatRangeInBounds.ZeroToOne)
    
    //trim view config
    cell.trimmerView?.setCurrentRange(chartContainer.trimRange)
    
    cell.trimmerView?.onChange = {[weak self] (newRange, event) in
      if event == .Started {
        cell.chartView?.isUserInteractionEnabled = false
      } else if event == .Ended {
        cell.chartView?.isUserInteractionEnabled = true
      }
      cell.chartView?.trimDisplayRange(to: newRange, with: event)
      chartContainer.updateTrimRange(to: newRange)
      
      let translatedBounds = chartContainer.chart.translatedBounds(for: newRange)
      let left = chartContainer.chart.datesVector[translatedBounds.lowerBound]
      let right = chartContainer.chart.datesVector[translatedBounds.upperBound]
      
      cell.headerView.label.text = self?.dateRangeFormatter.prettyDateStringFrom(left: left, right: right)
    }
    
    
    
    let theme = UIApplication.myDelegate.currentTheme
    cell.headerView.label.textColor = theme.mainTextColor
    cell.backgroundColor = theme.foregroundColor
  }

}

extension TGCAChartDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section < chartContainers.count {
      return (chartContainers[section].chart.title ?? "Untitled chart").uppercased()
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


class ChartContainer {
  let chart: DataChart
  var underlyingChartContainer: ChartContainer?
  
  private(set) var hiddenIndicies: Set<Int>
  private(set) var trimRange: CGFloatRangeInBounds
  
  
  init(chart: DataChart, hiddenIndicies: Set<Int> = []) {
    self.chart = chart
    self.trimRange = CGFloatRangeInBounds.ZeroToOne
    self.hiddenIndicies = hiddenIndicies
  }
  
  func updateTrimRange(to newRange: CGFloatRangeInBounds) {
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
