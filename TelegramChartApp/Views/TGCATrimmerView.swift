//
//  TGCATrimmerView.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

protocol TGCATrimmerViewDelegate: class {
  /**
   lmao
   
   - Parameters:
   - chartSlider ad asda sd
   - from (0, minimumRangeLength) to (100 - minimumRangeLength, 100)
   */
  func chartSlider(_ chartSlider: TGCATrimmerView, didChangeDisplayRange range: ClosedRange<CGFloat>)
  
}

//TODO: UIControl?
class TGCATrimmerView: UIView {
  
  weak var delegate: TGCATrimmerViewDelegate?
  
  /// The minimum range in percentage allowed for the trimming. Between 0.0 and 1.0.
  var minimumRangeLength: CGFloat = 0.25 {
    willSet {
      self.minimumRangeLength = max(0, min(newValue, 1))
      //TODO: what if was set when already small
      //TODO: also maximum range?
      
    }
  }
  
  var shoulderWidth: CGFloat = 15.0
  
  private let minRangeValue: CGFloat = 0.0
  private let maxRangeValue: CGFloat = 375.0
  // MARK: - Subviews
  private let trimmedAreaView = UIView()
  private let leftShoulderView = TGCATrimmerLeftShoulderView()
  private let rightShoulderView = TGCATrimmerRightShoulderView()
  private let leftMaskView = UIView()
  private let rightMaskView = UIView()
  
  // MARK: = Constraints
  
  private var currentLeftConstraint: CGFloat = 0
  private var currentRightConstraint: CGFloat = 0
  private var leftConstraint: NSLayoutConstraint?
  private var rightConstraint: NSLayoutConstraint?
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    backgroundColor = .clear
    layer.zPosition = 1
    setupTrimmedAreaView()
    setupShoulderViews()
    setupMaskView()
    setupGestures()
  }
  
  func setupTrimmedAreaView() {
    trimmedAreaView.layer.borderWidth = 2.0
    trimmedAreaView.layer.cornerRadius = 2.0
    trimmedAreaView.translatesAutoresizingMaskIntoConstraints = false
    trimmedAreaView.isUserInteractionEnabled = true
    addSubview(trimmedAreaView)
    trimmedAreaView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    trimmedAreaView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    leftConstraint = trimmedAreaView.leftAnchor.constraint(equalTo: leftAnchor)
    rightConstraint = trimmedAreaView.rightAnchor.constraint(equalTo: rightAnchor)
    leftConstraint?.isActive = true
    rightConstraint?.isActive = true
  }
  
  func setupShoulderViews() {
    leftShoulderView.isUserInteractionEnabled = true
    leftShoulderView.layer.cornerRadius = 2.0
    leftShoulderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(leftShoulderView)
    leftShoulderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    leftShoulderView.widthAnchor.constraint(equalToConstant: shoulderWidth).isActive = true
    leftShoulderView.leftAnchor.constraint(equalTo: trimmedAreaView.leftAnchor).isActive = true
    leftShoulderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    leftShoulderView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
    
    rightShoulderView.isUserInteractionEnabled = true
    rightShoulderView.layer.cornerRadius = 2.0
    rightShoulderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(rightShoulderView)
    rightShoulderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    rightShoulderView.widthAnchor.constraint(equalToConstant: shoulderWidth).isActive = true
    rightShoulderView.rightAnchor.constraint(equalTo: trimmedAreaView.rightAnchor).isActive = true
    rightShoulderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    rightShoulderView.backgroundColor = UIColor.red.withAlphaComponent(0.5)

  }
  
  private func setupMaskView() {
    leftMaskView.isUserInteractionEnabled = false
    leftMaskView.backgroundColor = .blue
    leftMaskView.alpha = 0.7
    leftMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftMaskView, belowSubview: leftShoulderView)
    leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    leftMaskView.rightAnchor.constraint(equalTo: leftShoulderView.centerXAnchor).isActive = true
    
    rightMaskView.isUserInteractionEnabled = false
    rightMaskView.backgroundColor = .blue
    rightMaskView.alpha = 0.7
    rightMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightMaskView, belowSubview: rightShoulderView)
    rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    rightMaskView.leftAnchor.constraint(equalTo: rightShoulderView.centerXAnchor).isActive = true
  }
  
  private func setupGestures() {
    for shoulderView in [trimmedAreaView, leftShoulderView, rightShoulderView] {
      let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
      shoulderView.addGestureRecognizer(panGestureRecognizer)
    }
  }
  
  @objc func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
    guard let view = panGestureRecognizer.view, let superView = panGestureRecognizer.view?.superview else { return }
    let isLeftGesture = view == leftShoulderView
    let isRightGesture = view == rightShoulderView
    switch panGestureRecognizer.state {
      
    case .began:
      if isLeftGesture {
        currentLeftConstraint = leftConstraint!.constant
      } else if isRightGesture {
        currentRightConstraint = rightConstraint!.constant
      } else {
        currentLeftConstraint = leftConstraint!.constant
        currentRightConstraint = rightConstraint!.constant
      }
      notifyRangeChanged()
    case .changed:
      let translation = panGestureRecognizer.translation(in: superView)
      if isLeftGesture {
        updateLeftConstraint(with: translation)
      } else if isRightGesture{
        updateRightConstraint(with: translation)
      } else {
        updateLeftConstraint(with: translation)
        updateRightConstraint(with: translation)
      }
      layoutIfNeeded()
      notifyRangeChanged()
    case .cancelled, .ended, .failed:
      notifyRangeChanged()
    default: break
    }
  }
  
  func notifyRangeChanged() {
    print(currentRange)
    delegate?.chartSlider(self, didChangeDisplayRange: currentRange)
  }
  
  private func updateLeftConstraint(with translation: CGPoint) {
    let maxConstraint = max(rightShoulderView.frame.origin.x - shoulderWidth - minimumDistanceBetweenShoulders, 0)
    let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
    leftConstraint?.constant = newConstraint
  }
  
  private func updateRightConstraint(with translation: CGPoint) {
    let maxConstraint = min(2 * shoulderWidth - frame.width + leftShoulderView.frame.origin.x + minimumDistanceBetweenShoulders, 0)
    let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
    rightConstraint?.constant = newConstraint
  }
  
  private var translatedMinimumRangeLenth: CGFloat {
    return minimumRangeLength * (maxRangeValue - minRangeValue) + minRangeValue
  }
  
  private var minimumDistanceBetweenShoulders: CGFloat {
    return frame.width * translatedMinimumRangeLenth / maxRangeValue
  }
  
  private func resetHandleViewPosition() {
    leftConstraint?.constant = 0
    rightConstraint?.constant = 0
    layoutIfNeeded()
    notifyRangeChanged()
  }
  
  /// The current start position of trimmed area in own coordinates.
  private var startPosition: CGFloat {
    return leftShoulderView.frame.origin.x
  }
  
  /// The current end position of trimmed area in own coordinates.
  private var endPosition: CGFloat {
    return rightShoulderView.frame.origin.x + rightShoulderView.frame.width
  }

  /// The current trimmed range. The left boundary is at which percentage the trim starts. The right boundary is at which percentage the trim ends. Possible values are subranges of 0.0...100.0.
  public var currentRange: ClosedRange<CGFloat> {
    //TODO: why is it 33 instead of 25
    let left = startPosition * maxRangeValue / frame.width
    let right = endPosition * maxRangeValue / frame.width
    return left...right
  }
  
}
