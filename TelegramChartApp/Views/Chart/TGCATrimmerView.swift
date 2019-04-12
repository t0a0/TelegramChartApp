//
//  TGCATrimmerView.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

enum DisplayRangeChangeEvent {
  case Started
  case Scrolled
  case Scaled
  case Ended
  case Reset
}

class TGCATrimmerView: UIView {
  static let borderWidth: CGFloat = 1.0
  static let shoulderWidth: CGFloat = 12.0

  var onChange: ((_ newRange: CGFloatRangeInBounds, _ event: DisplayRangeChangeEvent) -> ())?
  
  func setCurrentRange(_ range: CGFloatRangeInBounds, notify: Bool = false, animated: Bool = false) {
    
    func changes() {
      let curRange = currentRange
      if range.bounds == curRange.bounds {
        leftConstraint?.constant = curRange.range.lowerBound
        rightConstraint?.constant = -1 * (curRange.bounds.upperBound - curRange.range.upperBound)
      } else {
        let mappedRange = range.mapTo(newBounds: curRange.bounds).range
        leftConstraint?.constant = mappedRange.lowerBound
        rightConstraint?.constant = -1 * (curRange.bounds.upperBound - mappedRange.upperBound)
      }
      
      layoutIfNeeded()
    }
    
    if animated {
      UIView.animate(withDuration: TRIMMER_VIEW_ANIMATION_DURATION) {
        changes()
      }
    } else {
      changes()
    }
    
    if notify { notifyRangeChanged(event: .Reset) }
  }
  
  /// The minimum range allowed for the trimming. Between 0.0 and 1.0.
  private let minimumRangeLength: CGFloat = 0.2
  
  // MARK: - Subviews
  
  private let trimmedAreaView = UIView()
  private let leftShoulderView = TGCATrimmerLeftShoulderView()
  private let rightShoulderView = TGCATrimmerRightShoulderView()
  private let leftMaskView = UIView()
  private let rightMaskView = UIView()
  private let leftBackgroundView = UIView()
  private let rightBackgroundView = UIView()
  
  // MARK: - Constraints
  
  private var currentLeftConstraint: CGFloat = 0
  private var currentRightConstraint: CGFloat = 0
  private var leftConstraint: NSLayoutConstraint!
  private var rightConstraint: NSLayoutConstraint!
  
  // MARK: - Range change handling
  
  private func notifyRangeChanged(event: DisplayRangeChangeEvent) {
    onChange?(currentRange, event)
  }
  

  private var currentRange: CGFloatRangeInBounds {
    return CGFloatRangeInBounds(range: startPosition...endPosition, bounds: 0...bounds.width)
  }
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    backgroundColor = .clear
    layer.zPosition = 1
    setupTrimmedAreaView()
    setupShoulderViews()
    setupMaskViews()
    setupBackgroundViews()
    setupGestures()
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
  
  private func setupTrimmedAreaView() {
    trimmedAreaView.layer.borderWidth = TGCATrimmerView.borderWidth
    trimmedAreaView.layer.cornerRadius = TGCATrimmerView.shoulderWidth
    trimmedAreaView.layer.masksToBounds = true

    trimmedAreaView.translatesAutoresizingMaskIntoConstraints = false
    trimmedAreaView.isUserInteractionEnabled = true
    addSubview(trimmedAreaView)
    trimmedAreaView.layer.zPosition = -1
    trimmedAreaView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    trimmedAreaView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    leftConstraint = trimmedAreaView.leftAnchor.constraint(equalTo: leftAnchor)
    rightConstraint = trimmedAreaView.rightAnchor.constraint(equalTo: rightAnchor)
    leftConstraint.isActive = true
    rightConstraint.isActive = true
  }
  
  private func setupShoulderViews() {
    leftShoulderView.isUserInteractionEnabled = true
    leftShoulderView.layer.masksToBounds = true
    leftShoulderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(leftShoulderView)
    leftShoulderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    leftShoulderView.widthAnchor.constraint(equalToConstant: TGCATrimmerView.shoulderWidth).isActive = true
    leftShoulderView.leftAnchor.constraint(equalTo: trimmedAreaView.leftAnchor).isActive = true
    leftShoulderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    rightShoulderView.isUserInteractionEnabled = true
    rightShoulderView.layer.masksToBounds = true
    rightShoulderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(rightShoulderView)
    rightShoulderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    rightShoulderView.widthAnchor.constraint(equalToConstant: TGCATrimmerView.shoulderWidth).isActive = true
    rightShoulderView.rightAnchor.constraint(equalTo: trimmedAreaView.rightAnchor).isActive = true
    rightShoulderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }
  
  private func setupMaskViews() {
    leftMaskView.isUserInteractionEnabled = false
    leftMaskView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    leftMaskView.layer.masksToBounds = true
    leftMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftMaskView, belowSubview: leftShoulderView)
    leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    let leftMaskViewBottomConstraint = leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor)
    leftMaskViewBottomConstraint.isActive = true
    leftMaskViewBottomConstraint.constant = -1.0
    let leftMaskViewTopConstraint = leftMaskView.topAnchor.constraint(equalTo: topAnchor)
    leftMaskViewTopConstraint.isActive = true
    leftMaskViewTopConstraint.constant = 1.0
    leftMaskView.rightAnchor.constraint(equalTo: leftShoulderView.rightAnchor).isActive = true
    
    rightMaskView.isUserInteractionEnabled = false
    rightMaskView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    rightMaskView.layer.masksToBounds = true
    rightMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightMaskView, belowSubview: rightShoulderView)
    rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    let rightMaskViewBottomConstraint = rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor)
    rightMaskViewBottomConstraint.isActive = true
    rightMaskViewBottomConstraint.constant = -1.0
    let rightMaskViewTopConstraint = rightMaskView.topAnchor.constraint(equalTo: topAnchor)
    rightMaskViewTopConstraint.isActive = true
    rightMaskViewTopConstraint.constant = 1.0
    rightMaskView.leftAnchor.constraint(equalTo: rightShoulderView.leftAnchor).isActive = true
  }
  
  private func setupBackgroundViews() {
    leftBackgroundView.isUserInteractionEnabled = false
    leftBackgroundView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    leftBackgroundView.layer.masksToBounds = true
    leftBackgroundView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftBackgroundView, belowSubview: leftShoulderView)
    leftBackgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    let leftBackgroundViewBottomConstraint = leftBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
    leftBackgroundViewBottomConstraint.isActive = true
    leftBackgroundViewBottomConstraint.constant = -1.0
    let leftBackgroundViewTopConstraint = leftBackgroundView.topAnchor.constraint(equalTo: topAnchor)
    leftBackgroundViewTopConstraint.isActive = true
    leftBackgroundViewTopConstraint.constant = 1.0
    leftBackgroundView.rightAnchor.constraint(equalTo: leftShoulderView.rightAnchor).isActive = true
    leftBackgroundView.layer.zPosition = -2
    
    rightBackgroundView.isUserInteractionEnabled = false
    rightBackgroundView.layer.cornerRadius = TGCATrimmerView.shoulderWidth * 0.75
    rightBackgroundView.layer.masksToBounds = true
    rightBackgroundView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightBackgroundView, belowSubview: rightShoulderView)
    rightBackgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    let rightBackgroundViewBottomConstraint = rightBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
    rightBackgroundViewBottomConstraint.isActive = true
    rightBackgroundViewBottomConstraint.constant = -1.0
    let rightBackgroundViewTopConstraint = rightBackgroundView.topAnchor.constraint(equalTo: topAnchor)
    rightBackgroundViewTopConstraint.isActive = true
    rightBackgroundViewTopConstraint.constant = 1.0
    rightBackgroundView.leftAnchor.constraint(equalTo: rightShoulderView.leftAnchor).isActive = true
    rightBackgroundView.layer.zPosition = -2

  }
  
  // MARK: - Gestures
  
  private func setupGestures() {
    for view in [trimmedAreaView, leftShoulderView, rightShoulderView] {
      let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
      view.addGestureRecognizer(panGestureRecognizer)
    }
  }
  
  private func deactivateShoulderGestureRecognizers() {
    deactivateLeftShoulderGestureRecognizer()
    deactivateRightShoulderGestureRecognizer()
  }
  
  private func deactivateLeftShoulderGestureRecognizer() {
    leftShoulderView.gestureRecognizers?.forEach{$0.isEnabled = false}
  }
  
  private func deactivateRightShoulderGestureRecognizer() {
    rightShoulderView.gestureRecognizers?.forEach{$0.isEnabled = false}
  }
  
  private func deactivateTrimmedAreaGestureRecognizers() {
    if let gestureRecognizers = trimmedAreaView.gestureRecognizers {
      for gesture in gestureRecognizers {
        gesture.isEnabled = false
      }
    }
  }
  
  private func reactivateGestureRecognizers() {
    [trimmedAreaView, leftShoulderView, rightShoulderView].forEach{$0.gestureRecognizers?.forEach{$0.isEnabled = true}}
  }
  
  @objc private func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    guard let view = panGestureRecognizer.view, let superView = panGestureRecognizer.view?.superview else { return }
    let isLeftGesture = view == leftShoulderView
    let isRightGesture = view == rightShoulderView
    switch panGestureRecognizer.state {
      
    case .began:
      if isLeftGesture {
        deactivateTrimmedAreaGestureRecognizers()
        deactivateRightShoulderGestureRecognizer()
        currentLeftConstraint = leftConstraint.constant
      } else if isRightGesture {
        deactivateTrimmedAreaGestureRecognizers()
        deactivateLeftShoulderGestureRecognizer()
        currentRightConstraint = rightConstraint.constant
      } else {
        deactivateShoulderGestureRecognizers()
        currentLeftConstraint = leftConstraint.constant
      }
      notifyRangeChanged(event: .Started)
    case .changed:
      let translation = panGestureRecognizer.translation(in: superView)
      if isLeftGesture {
        updateLeftConstraint(with: translation)
        layoutIfNeeded()
        notifyRangeChanged(event: .Scaled)
      } else if isRightGesture{
        updateRightConstraint(with: translation)
        layoutIfNeeded()
        notifyRangeChanged(event: .Scaled)
      } else {
        updateBothConstraints(with: translation)
        layoutIfNeeded()
        notifyRangeChanged(event: .Scrolled)
      }
      
    case .cancelled, .ended, .failed:
      reactivateGestureRecognizers()
      notifyRangeChanged(event: .Ended)
    default: break
    }
  }
  
  // MARK: - Updating constraints
  
  private func updateLeftConstraint(with translation: CGPoint) {
    let maxConstraint = max(rightShoulderView.frame.origin.x + rightShoulderView.frame.width - minimumDistanceBetweenShoulders, 0)
    let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
    leftConstraint.constant = newConstraint
  }
  
  private func updateRightConstraint(with translation: CGPoint) {
    let maxConstraint = min(leftShoulderView.frame.origin.x + minimumDistanceBetweenShoulders - frame.size.width, 0)
    let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
    rightConstraint.constant = newConstraint
  }
  
  private func updateBothConstraints(with translation: CGPoint) {
    let pendingChange = currentLeftConstraint + translation.x - leftConstraint.constant
    var cappedChange = pendingChange
    if leftConstraint.constant + pendingChange < 0 {
      cappedChange = -leftConstraint.constant
    }
    
    if rightConstraint.constant + cappedChange > 0 {
      cappedChange = -rightConstraint.constant
    }
    
    leftConstraint.constant = leftConstraint.constant + cappedChange
    rightConstraint.constant = rightConstraint.constant + cappedChange
  }
  
  override var bounds: CGRect {
    didSet {
      guard let lc = leftConstraint, let rc = rightConstraint else {
        return
      }
      
      var widthChangeCoefficient = bounds.width / oldValue.width
      if widthChangeCoefficient == CGFloat.infinity { widthChangeCoefficient = 0.0}
      lc.constant = lc.constant * widthChangeCoefficient
      rc.constant = rc.constant * widthChangeCoefficient
    }
  }
  
  // MARK: - Helpers
  
  private var minimumDistanceBetweenShoulders: CGFloat {
    return minimumRangeLength * bounds.width
  }
  
  private func resetHandleViewPosition() {
    leftConstraint.constant = 0
    rightConstraint.constant = 0
    layoutIfNeeded()
    notifyRangeChanged(event: .Reset)
  }
  
  /// The current start position of trimmed area in own coordinates.
  private var startPosition: CGFloat {
    return leftConstraint.constant
  }
  
  /// The current end position of trimmed area in own coordinates.
  private var endPosition: CGFloat {
    return bounds.width + rightConstraint.constant
  }
  
}

extension TGCATrimmerView: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      leftBackgroundView.backgroundColor = theme.backgroundColor
      rightBackgroundView.backgroundColor = theme.backgroundColor
      trimmedAreaView.backgroundColor = theme.foregroundColor
      leftShoulderView.backgroundColor = theme.trimmerShoulderColor
      rightShoulderView.backgroundColor = theme.trimmerShoulderColor
      leftShoulderView.imageView.backgroundColor = theme.trimmerShoulderColor
      rightShoulderView.imageView.backgroundColor = theme.trimmerShoulderColor
      leftMaskView.backgroundColor = theme.trimmerMaskColor
      rightMaskView.backgroundColor = theme.trimmerMaskColor
    }
    
    func applyLayerChanges() {
      trimmedAreaView.layer.borderColor = theme.trimmerShoulderColor.cgColor
    }
    
    if animated {
      UIView.animate(withDuration: ANIMATION_DURATION) {
        applyChanges()
      }
      
      let colorANim = CABasicAnimation(keyPath: "borderColor");
      colorANim.fromValue = trimmedAreaView.layer.borderColor
      applyLayerChanges()
      colorANim.toValue = theme.trimmerShoulderColor.cgColor
      colorANim.duration = ANIMATION_DURATION
      trimmedAreaView.layer.add(colorANim, forKey: nil)
      
    } else {
      applyChanges()
      applyLayerChanges()
    }
  }
  
}
