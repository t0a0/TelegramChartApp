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

  /**
   Calls to notify that the trimmed area on trimmer view has changed.
   
   - Parameters:
   - newRange: Min is 0...minimumRangeLength, max is (1 - minimumRangeLength)...1
   - event: An event that triggered the change in display range
   
   */
  var onChange: ((_ newRange: ClosedRange<CGFloat>, _ event: DisplayRangeChangeEvent) -> ())?
  
  func setCurrentRange(_ range: ClosedRange<CGFloat>, notify: Bool = false) {
    leftConstraint?.constant = (range.lowerBound / (totalRange.upperBound - totalRange.lowerBound)) * frame.width
    rightConstraint?.constant = -1 * (frame.width - (range.upperBound / (totalRange.upperBound - totalRange.lowerBound)) * frame.width)
    layoutIfNeeded()
    if notify { notifyRangeChanged(event: .Reset) }
  }
  
  /// The minimum range allowed for the trimming. Between 0.0 and 1.0.
  private let minimumRangeLength: CGFloat = 0.2
  private let totalRange = ZORange
  
  // MARK: - Subviews
  
  private let trimmedAreaView = UIView()
  private let leftShoulderView = TGCATrimmerLeftShoulderView()
  private let rightShoulderView = TGCATrimmerRightShoulderView()
  private let leftMaskView = UIView()
  private let rightMaskView = UIView()
  
  // MARK: - Constraints
  
  private var currentLeftConstraint: CGFloat = 0
  private var currentRightConstraint: CGFloat = 0
  private var leftConstraint: NSLayoutConstraint!
  private var rightConstraint: NSLayoutConstraint!
  
  // MARK: - Range change handling
  
  private func notifyRangeChanged(event: DisplayRangeChangeEvent) {
    onChange?(currentRange, event)
  }
  
  /// The current trimmed range. The left boundary is at which percentage the trim starts. The right boundary is at which percentage the trim ends. Possible values are subranges of 0.0...1.0.
  var currentRange: ClosedRange<CGFloat> {
    let left = startPosition * totalRange.upperBound / frame.width
    let right = endPosition * totalRange.upperBound / frame.width
    return left...right
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
    leftShoulderView.backgroundColor = UIColor.lightGray

    rightShoulderView.isUserInteractionEnabled = true
    rightShoulderView.layer.masksToBounds = true
    rightShoulderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(rightShoulderView)
    rightShoulderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    rightShoulderView.widthAnchor.constraint(equalToConstant: TGCATrimmerView.shoulderWidth).isActive = true
    rightShoulderView.rightAnchor.constraint(equalTo: trimmedAreaView.rightAnchor).isActive = true
    rightShoulderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    rightShoulderView.backgroundColor = UIColor.lightGray
  }
  
  private func setupMaskViews() {
    leftMaskView.isUserInteractionEnabled = false
    leftMaskView.backgroundColor = .lightGray
    leftMaskView.alpha = 0.8
    leftMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftMaskView, belowSubview: leftShoulderView)
    leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    let leftMaskViewBottomConstraint = leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor)
    leftMaskViewBottomConstraint.isActive = true
    leftMaskViewBottomConstraint.constant = -2.0
    let leftMaskViewTopConstraint = leftMaskView.topAnchor.constraint(equalTo: topAnchor)
    leftMaskViewTopConstraint.isActive = true
    leftMaskViewTopConstraint.constant = 2.0
    leftMaskView.rightAnchor.constraint(equalTo: leftShoulderView.leftAnchor).isActive = true
    
    rightMaskView.isUserInteractionEnabled = false
    rightMaskView.backgroundColor = .lightGray
    rightMaskView.alpha = 0.8
    rightMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightMaskView, belowSubview: rightShoulderView)
    rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    let rightMaskViewBottomConstraint = rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor)
    rightMaskViewBottomConstraint.isActive = true
    rightMaskViewBottomConstraint.constant = -2.0
    let rightMaskViewTopConstraint = rightMaskView.topAnchor.constraint(equalTo: topAnchor)
    rightMaskViewTopConstraint.isActive = true
    rightMaskViewTopConstraint.constant = 2.0
    rightMaskView.leftAnchor.constraint(equalTo: rightShoulderView.rightAnchor).isActive = true
  }
  
  // MARK: - Gestures
  
  private func setupGestures() {
    for view in [trimmedAreaView, leftShoulderView, rightShoulderView] {
      let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
      view.addGestureRecognizer(panGestureRecognizer)
    }
  }
  
  private func deactivateShoulderGestureRecognizers() {
    for shoulderView in [leftShoulderView, rightShoulderView] {
      if let gestureRecognizers = shoulderView.gestureRecognizers {
        for gesture in gestureRecognizers {
          gesture.isEnabled = false
        }
      }
    }
  }
  
  private func deactivateTrimmedAreaGestureRecognizers() {
    if let gestureRecognizers = trimmedAreaView.gestureRecognizers {
      for gesture in gestureRecognizers {
        gesture.isEnabled = false
      }
    }
  }
  
  private func reactivateGestureRecognizers() {
    for view in [trimmedAreaView, leftShoulderView, rightShoulderView] {
      if let gestureRecognizers = view.gestureRecognizers {
        for gesture in gestureRecognizers {
          gesture.isEnabled = true
        }
      }
    }
  }
  
  @objc private func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    guard let view = panGestureRecognizer.view, let superView = panGestureRecognizer.view?.superview else { return }
    let isLeftGesture = view == leftShoulderView
    let isRightGesture = view == rightShoulderView
    switch panGestureRecognizer.state {
      
    case .began:
      if isLeftGesture {
        deactivateTrimmedAreaGestureRecognizers()
        currentLeftConstraint = leftConstraint.constant
      } else if isRightGesture {
        deactivateTrimmedAreaGestureRecognizers()
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
  
  private var translatedMinimumRangeLenth: CGFloat {
    return minimumRangeLength * (totalRange.upperBound - totalRange.lowerBound) + totalRange.lowerBound
  }
  
  private var minimumDistanceBetweenShoulders: CGFloat {
    return frame.width * translatedMinimumRangeLenth / totalRange.upperBound
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
    return frame.width + rightConstraint.constant
  }
  
}

extension TGCATrimmerView: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      leftShoulderView.backgroundColor = theme.trimmerShoulderColor
      rightShoulderView.backgroundColor = theme.trimmerShoulderColor
      leftMaskView.backgroundColor = theme.backgroundColor
      rightMaskView.backgroundColor = theme.backgroundColor
    }
    
    func applyLayerChanges() {
      trimmedAreaView.layer.borderColor = theme.trimmerShoulderColor.cgColor
    }
    
    if animated {
      UIView.animate(withDuration: ANIMATION_DURATION) {
        applyChanges()
      }
      
      CATransaction.begin()
      CATransaction.setAnimationDuration(ANIMATION_DURATION)
      applyLayerChanges()
      CATransaction.commit()
      
    } else {
      applyChanges()
      applyLayerChanges()
    }
  }
  
}
