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
  
  // MARK: - Outlets
  
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var disclosureImageView: UIImageView!
  @IBOutlet weak var columnsStackView: UIStackView!
  @IBOutlet weak var leftStackView: UIStackView!
  @IBOutlet weak var middleStackView: UIStackView!
  @IBOutlet weak var rightStackView: UIStackView!
  @IBOutlet weak var headerStackView: UIStackView!
  
  // MARK: - Constraints
  
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  @IBOutlet weak var leadingContsraint: NSLayoutConstraint!
  @IBOutlet weak var rightStackViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var leftStackViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var headerStackViewHeightConstraint: NSLayoutConstraint!
  
  // MARK: - Formatters
  
  private lazy var dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.dateFormat = "EE, dd MMM Y"
    df.timeZone = TimeZone(secondsFromGMT: 0)
    return df
  }()
  
  private lazy var timeFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "HH:mm"
    return df
  }()
  
  private lazy var numberFormatter: NumberFormatter = {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.minimumFractionDigits = 0
    nf.maximumFractionDigits = 2
    nf.usesGroupingSeparator = true
    nf.groupingSeparator = ","
    return nf
  }()
  
  private var maxPossibleLabels: Int = 0
  
  var onTap: (()->())?
  var onLongTap: (()->())?
  
  // MARK: - Init
  
  init(maxPossibleLabels: Int) {
    super.init(frame: CGRect.zero)
    self.maxPossibleLabels = maxPossibleLabels
    commonInit()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit () {
    Bundle.main.loadNibNamed("TGCAChartAnnotationView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    layer.masksToBounds = true
    layer.cornerRadius = 6.0
    prepareArrangedLabels(for: maxPossibleLabels)
    headerLabel.font = AnnotationViewConstants.headerFont
    applyCurrentTheme()
    layer.anchorPoint = CGPoint(x: 0.5, y: 0)
    addGestureRecognizers()
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
  
  // MARK: - Gestures
  
  func addGestureRecognizers() {
    let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
    addGestureRecognizer(tapGR)
    let longTapGR = UILongPressGestureRecognizer(target: self, action: #selector(longTapped(_:)))
    longTapGR.minimumPressDuration = 0.75
    addGestureRecognizer(longTapGR)
  }
  
  @objc func tapped(_ sender: UITapGestureRecognizer) {
    onTap?()
  }
  
  @objc func longTapped(_ sender: UITapGestureRecognizer) {
    onLongTap?()
  }
  
  // MARK: - Configuration
  
  private var biggestObservedWidth: CGFloat = 0
  private var biggestObservedRightStackViewWidth: CGFloat = 0
  private var currentConfiguration: AnnotationViewConfiguration?
  
  
  func configure(with configuration: AnnotationViewConfiguration) {
    headerLabel.text = configuration.mode == .Date ? dateFormatter.string(from: configuration.date) : timeFormatter.string(from: configuration.date)
    disclosureImageView.isHidden = !configuration.showsDisclosureIcon
    
    var headerWidth = headerLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: headerStackViewHeightConstraint.constant)).width
    if configuration.showsDisclosureIcon {
      //headerStackViewHeightConstraint because image view width is that
      headerWidth += headerStackViewHeightConstraint.constant/2 + headerStackView.spacing
    }
    
    let count = configuration.coloredValues.count
    
    
    leftStackView.isHidden = !configuration.showsLeftColumn
    
    var maxMiddleLabelWidth: CGFloat = 0
    var maxRightLabelWidth: CGFloat = 0

    for i in 0..<count {
      let coloredValue = configuration.coloredValues[i]
      
      let rightLabel = rightArrangedLabels[i]
      rightLabel.textColor = coloredValue.color ?? UIApplication.myDelegate.currentTheme.annotationLabelColor
      rightLabel.text = transformValueToString(coloredValue.value)
      let rightSize = rightLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: AnnotationViewConstants.heightForLabel))
      maxRightLabelWidth = max(rightSize.width, maxRightLabelWidth)
      
      let middleLabel = middleArrangedLabels[i]
      middleLabel.text = coloredValue.title
      let middleSize = middleLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: AnnotationViewConstants.heightForLabel))
      maxMiddleLabelWidth = max(middleSize.width, maxMiddleLabelWidth)
    }
    
    if configuration.showsLeftColumn {
      for i in 0..<count {
        let coloredValue = configuration.coloredValues[i]
        let leftLabel = leftArrangedLabels[i]
        leftLabel.text = coloredValue.prefix ?? ""
      }
    }
    
    maxRightLabelWidth = ceil(maxRightLabelWidth)
    if maxRightLabelWidth > biggestObservedRightStackViewWidth {
      biggestObservedRightStackViewWidth = maxRightLabelWidth
    }
    rightStackViewWidthConstraint.constant = biggestObservedRightStackViewWidth
    
    let height = (AnnotationViewConstants.heightForLabel + AnnotationViewConstants.labelSpacing) * CGFloat(configuration.coloredValues.count) + headerStackViewHeightConstraint.constant
    var width = rightStackViewWidthConstraint.constant + columnsStackView.spacing + ceil(maxMiddleLabelWidth)
    if configuration.showsLeftColumn {
      width += leftStackViewWidthConstraint.constant + columnsStackView.spacing
    }
    
    width = max(width, ceil(headerWidth))
    
    let totalWidth = width + leadingContsraint.constant + trailingConstraint.constant
    
    if totalWidth > biggestObservedWidth {
      biggestObservedWidth = totalWidth
    }
    
    let newSize = CGSize(width: biggestObservedWidth, height: height + topConstraint.constant + bottomConstraint.constant)
    
    //IMPORTANT: should be before bounds change
    showHideLabels(withCount: count)
    currentConfiguration = configuration

    if superview != nil && bounds.size != newSize {
      UIView.animate(withDuration: ANIMATION_DURATION) { [weak self] in
        self?.bounds.size = newSize
        self?.layoutIfNeeded()
      }
    } else {
      bounds.size = newSize
    }
  }

  // MARK: - Helper methods
  
  private func transformValueToString(_ value: CGFloat) -> String {
    return numberFormatter.string(from: NSNumber(floatLiteral: Double(value))) ?? "\(value)"
  }
  
  private struct AnnotationViewConstants {
    static let headerFont = UIFont.systemFont(ofSize: 12.0, weight: .bold)
    static let leftFont = UIFont.systemFont(ofSize: 11.0, weight: .bold)
    static let middleFont = UIFont.systemFont(ofSize: 11.0)
    static let rightFont = UIFont.systemFont(ofSize: 11.0, weight: .bold)
    static let labelSpacing: CGFloat = 2.0 //IF I CHANGE THIS -> ALSO CHANGE IN .XIB for stack views
    
    static let heightForLabel: CGFloat = 13.0
  }
  
  private var leftArrangedLabels = [UILabel]()
  private var middleArrangedLabels = [UILabel]()
  private var rightArrangedLabels = [UILabel]()
  
  private func showHideLabels(withCount count: Int) {
    for i in 0..<maxPossibleLabels {
      leftArrangedLabels[i].isHidden = i >= count
      middleArrangedLabels[i].isHidden = i >= count
      rightArrangedLabels[i].isHidden = i >= count
    }
  }
  
  private func prepareArrangedLabels(for count: Int) {
    for _ in 0..<count {
      let leftLabel = generateLeftLabel()
      leftStackView.addArrangedSubview(leftLabel)
      leftArrangedLabels.append(leftLabel)
      
      let middleLabel = generateMiddleLabel()
      middleStackView.addArrangedSubview(middleLabel)
      middleArrangedLabels.append(middleLabel)
      
      let rightLabel = generateRightLabel()
      rightStackView.addArrangedSubview(rightLabel)
      rightArrangedLabels.append(rightLabel)
    }
  }
  
  private func generateLeftLabel() -> UILabel {
    let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: AnnotationViewConstants.heightForLabel)))
    label.numberOfLines = 1
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .right
    label.font = AnnotationViewConstants.leftFont
    return label
  }
  
  private func generateMiddleLabel() -> UILabel {
    let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: AnnotationViewConstants.heightForLabel)))
    label.numberOfLines = 1
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .left
    label.font = AnnotationViewConstants.middleFont
    return label
  }
  
  private func generateRightLabel() -> UILabel {
    let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: AnnotationViewConstants.heightForLabel)))
    label.numberOfLines = 1
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .right
    label.font = AnnotationViewConstants.rightFont
    return label
  }
  
  //MARK: - Structs
  enum AnnotationConfigurationMode {
    case Date
    case Time
  }
  
  struct ColoredValue {
    let title: String
    let value: CGFloat
    let color: UIColor?
    let prefix: String?
    
    init(title: String, value: CGFloat, color: UIColor?, prefix: String? = nil) {
      self.title = title
      self.value = value
      self.color = color
      self.prefix = prefix
    }
  }
  
  struct AnnotationViewConfiguration {
    let date: Date
    let showsDisclosureIcon: Bool
    let mode: AnnotationConfigurationMode
    let showsLeftColumn: Bool
    let coloredValues: [ColoredValue]
  }
  
}

extension TGCAChartAnnotationView: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      disclosureImageView.tintColor = theme.annotationDisclosureIndicatorColor
      disclosureImageView.backgroundColor = theme.annotationColor

      backgroundColor = theme.annotationColor
      
      headerLabel.textColor = theme.annotationLabelColor
      leftArrangedLabels.forEach{
        $0.textColor = theme.annotationLabelColor
      }
      middleArrangedLabels.forEach{
        $0.textColor = theme.annotationLabelColor
      }
      
      if let currentConfig = currentConfiguration {
        for i in 0..<currentConfig.coloredValues.count {
          if currentConfig.coloredValues[i].color == nil {
            rightArrangedLabels[i].textColor = theme.annotationLabelColor
          }
        }
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
