//
//  TGCAChartAnnotationView.swift
//  TelegramChartApp
//
//  Created by Igor on 17/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAChartAnnotationView: UIView, ThemeChangeObserving {
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var valuesStackView: UIStackView!
  
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  @IBOutlet weak var leadingContsraint: NSLayoutConstraint!
  private let dateFormatter = DateFormatter()
  private let numberFormatter = NumberFormatter()
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
    label.numberOfLines = 2
    label.lineBreakMode = .byWordWrapping
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
  
  internal func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  private func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      backgroundColor = theme.annotationColor
      label.textColor = theme.annotationLabelColor
    }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
    
  }
  
  // MARK: - Configuration
  
  typealias ColoredValue = (value: CGFloat, color: UIColor)
  
  func configure(date: Date, coloredValues: [ColoredValue]) -> CGSize {
    for subview in valuesStackView.subviews {
      subview.removeFromSuperview()
    }

    label.attributedText = transformDateToString(date)
    var maxLabelWidth: CGFloat = 0
    var sumOfHeights: CGFloat = 0
    for coloredValue in coloredValues {
      let label = UILabel(frame: CGRect.zero)
      label.numberOfLines = 1
      label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
      label.textColor = coloredValue.color
      label.text = transformValueToString(coloredValue.value)
      label.sizeToFit()
      valuesStackView.addArrangedSubview(label)
      maxLabelWidth = max(label.bounds.width, maxLabelWidth)
      sumOfHeights += label.bounds.height
    }
    label.sizeToFit()
    let separationWidth: CGFloat = abs(maxLabelWidth - label.bounds.width) > 10 ? 0 : 10
    let width = max(maxLabelWidth, label.bounds.width) * 2 + separationWidth
    let height = max(sumOfHeights, label.bounds.height)
    let newSize = CGSize(width: width + leadingContsraint.constant + trailingConstraint.constant, height: height + topConstraint.constant + bottomConstraint.constant)
    bounds = CGRect(origin: bounds.origin, size: newSize)
    return bounds.size
  }
  
  private func transformValueToString(_ value: CGFloat) -> String {
    return numberFormatter.string(from: NSNumber(floatLiteral: Double(value))) ?? "\(value)"
  }
  
  private func transformDateToString(_ date: Date) -> NSAttributedString {
    dateFormatter.dateFormat = "MMM dd"
    let monthDayString = dateFormatter.string(from: date)
    dateFormatter.dateFormat = "YYYY"
    let yearString = dateFormatter.string(from: date)
    let mutableString = NSMutableAttributedString(string: monthDayString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: .bold)])
    mutableString.append(NSAttributedString(string: "\n" + yearString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)]))
    return mutableString
  }
  
}
