//
//  TGCAChartAnnotationView.swift
//  TelegramChartApp
//
//  Created by Igor on 17/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAChartAnnotationView: UIView {
  
  typealias ColoredValue = (value: CGFloat, color: UIColor)
  
  // MARK: - Outlets
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var topLabel: UILabel!
  @IBOutlet weak var bottomLabel: UILabel!
  @IBOutlet weak var valuesStackView: UIStackView!
  
  // MARK: - Constraints
  
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  @IBOutlet weak var leadingContsraint: NSLayoutConstraint!
  
  // MARK: - Formatters
  
  private let dateFormatter = DateFormatter()
  private let numberFormatter = NumberFormatter()
  
  private func configureNumberFormatter() {
    numberFormatter.numberStyle = .decimal
    numberFormatter.minimumFractionDigits = 0
    numberFormatter.maximumFractionDigits = 2
    numberFormatter.locale = Locale.current
    numberFormatter.usesGroupingSeparator = true
    numberFormatter.groupingSeparator = ","
  }
  
  private func configureDateFormatter() {
    dateFormatter.locale = Locale.current
  }
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit () {
    configureNumberFormatter()
    configureDateFormatter()
    Bundle.main.loadNibNamed("TGCAChartAnnotationView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    layer.masksToBounds = true
    layer.cornerRadius = 6.0
    applyCurrentTheme()
  }
  
  override func didMoveToWindow() {
    if window != nil {
      subscribe()
    }
  }
  
  override func willMove(toWindow newWindow: UIWindow?) {
    if newWindow == nil {
      unsubscribe()
    }
  }
  
  // MARK: - Configuration
  
  func configure(date: Date, coloredValues: [ColoredValue]) -> CGSize {
    prepareArrangedLabels(withCount: coloredValues.count)
    
    let texts = transformDateToString(date)
    topLabel.text = texts.dateString
    bottomLabel.text = texts.yearString
    var maxLabelWidth: CGFloat = 0
    for i in 0..<coloredValues.count {
      let coloredValue = coloredValues[i]
      let label = arrangedLabels[i]
      label.textColor = coloredValue.color
      label.text = transformValueToString(coloredValue.value)
      let size = label.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: heightForLabel))
      maxLabelWidth = max(size.width, maxLabelWidth)
    }
    let widthThatFitsTopLabel: CGFloat = 50.0
    
    let width = max(maxLabelWidth, widthThatFitsTopLabel) * 2
    let height = max((heightForLabel + 2.0) * CGFloat(coloredValues.count), 40.0)
    let newSize = CGSize(width: width + leadingContsraint.constant + trailingConstraint.constant, height: height + topConstraint.constant + bottomConstraint.constant)
    
    bounds = CGRect(origin: bounds.origin, size: newSize)
    return bounds.size
  }

  // MARK: - Helper methods
  
  private func transformValueToString(_ value: CGFloat) -> String {
    return numberFormatter.string(from: NSNumber(floatLiteral: Double(value))) ?? "\(value)"
  }
  
  private func transformDateToString(_ date: Date) -> (dateString: String, yearString: String) {
    dateFormatter.dateFormat = "MMM dd"
    let monthDayString = dateFormatter.string(from: date)
    dateFormatter.dateFormat = "YYYY"
    let yearString = dateFormatter.string(from: date)
    return (monthDayString, yearString)
  }
  
  private let boldFont = UIFont.systemFont(ofSize: 13.0, weight: .bold)
  private let heightForLabel: CGFloat = 16.0
  
  private var arrangedLabels = [UILabel]()
  
  func prepareArrangedLabels(withCount count: Int) {
    let difference = arrangedLabels.count - count
    if difference > 0 {
      for _ in 0..<difference {
        let label = arrangedLabels.popLast()
        label?.removeFromSuperview()
      }
    } else if difference < 0 {
      for _ in difference..<0 {
        let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: heightForLabel)))
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.font = boldFont
        valuesStackView.addArrangedSubview(label)
        arrangedLabels.append(label)
      }
    }
  }
  
}

extension TGCAChartAnnotationView: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      backgroundColor = theme.annotationColor
      topLabel.textColor = theme.annotationLabelColor
      bottomLabel.textColor = theme.annotationLabelColor
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
