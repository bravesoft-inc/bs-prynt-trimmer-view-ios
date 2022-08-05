//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: AnyObject {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {
    // MARK: - Properties
    @IBInspectable public var borderWidth: CGFloat = 2 {
        didSet {
            setupBorderWidth()
        }
    }
    
    @IBInspectable public var cornerRadius: CGFloat = 2 {
        didSet {
            setupCornerRadius()
        }
    }
    
    @IBInspectable public var handleWidth: CGFloat = 16 {
        didSet {
            setupSubviews()
        }
    }
    
    @IBInspectable public var positionBarWidth: CGFloat = 4 {
        didSet {
            setupPositionBar()
        }
    }
    
    @IBInspectable public var isHiddenHandle: Bool = false {
        didSet {
            updateHandleHidden()
            setupGestures()
        }
    }
    
    @IBInspectable public var isMovePositionBar: Bool = false {
        didSet {
            setupPositionBar()
            setupGestures()
        }
    }
    
    @IBInspectable public var isShowTimeLabel: Bool = false {
        didSet {
            setupPositionBar()
            setupGestures()
        }
    }
    
    @IBInspectable public var assetPreviewMargin: CGFloat = 0 {
        didSet {
            resetAssetPreviews()
        }
    }
    
    @IBInspectable public var assetPreviewBorderWidth: CGFloat = 0 {
        didSet {
            setupAssetPreviewBorderWidth()
        }
    }
    
    @IBInspectable public var assetPreviewCornerRadius: CGFloat = 0 {
        didSet {
            setupAssetPreviewCornerRadius()
        }
    }
    
    public var isMoveTrimmerViewItem: Bool = false
    
    // MARK: View Customization
    
    public var customLeftHandleView: UIView? {
        didSet {
            setupLeftHandleView()
        }
    }
    public var customRightHandleView: UIView? {
        didSet {
            setupRightHandleView()
        }
    }
    public var customPositionBar: UIView? {
        didSet {
            setupPositionBar()
        }
    }
    
    // MARK: Color Customization

    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.white {
        didSet {
            updateMainColor()
        }
    }

    /// The color of the handles on the side of the view
    @IBInspectable public var handleColor: UIColor = UIColor.gray {
        didSet {
            updateHandleColor()
        }
    }

    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }

    /// The color used to mask unselected parts of the video
    @IBInspectable public var maskColor: UIColor = UIColor.white {
        didSet {
            leftMaskView.backgroundColor = maskColor
            rightMaskView.backgroundColor = maskColor
        }
    }

    // MARK: Interface
    public weak var delegate: TrimmerViewDelegate?

    // MARK: Subviews

    private let trimView = UIView()
    private let leftHandleView = HandlerView()
    private let rightHandleView = HandlerView()
    private let timeLabelView = TimeLabelView()
    private let timeLabelViewSize = CGSize(width: 64.0, height: 24.0)
    private let positionBar = UIView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftHandleKnobCenter = UIView()
    private let rightHandleKnobCenter = UIView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()

    // MARK: Constraints

    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var currentPositionConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?
    private var timeLabelConstraint: NSLayoutConstraint?

    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 0.3
    
    private var isLandscape: Bool = false
    
    private var tmpStartTime: CMTime = .zero
    private var tmpEndTime: CMTime = .zero
    private var tmpCurrentTime: CMTime = .zero

    // MARK: - View & constraints configurations

    override func setupSubviews() {
        super.setupSubviews()
        
        setupBorderWidth()
        setupCornerRadius()
        setupAssetPreviewBorderWidth()
        setupAssetPreviewCornerRadius()
        
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupPositionBar()
        setupGestures()
        updateMainColor()
        updateHandleColor()
        registerOrientationChangedNotification()
        
        setupTimeLabelView()
    }
    
    func setupTimeLabelView() {
        timeLabelView.removeFromSuperview()
        timeLabelView.isHidden = true
        timeLabelView.isUserInteractionEnabled = false
        timeLabelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabelView)
        
        timeLabelView.widthAnchor.constraint(equalToConstant: timeLabelViewSize.width).isActive = true
        timeLabelView.heightAnchor.constraint(equalToConstant: timeLabelViewSize.height).isActive = true
        timeLabelView.topAnchor.constraint(equalTo: trimView.topAnchor, constant: -timeLabelViewSize.height).isActive = true
        
        timeLabelConstraint = timeLabelView.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: -timeLabelConstant())
        timeLabelConstraint?.isActive = true
    }
    
    private func timeLabelConstant() -> CGFloat {
        (timeLabelViewSize.width - positionBarWidth) / 2
    }
    
    func resetAssetPreviews() {
        assetPreview.removeFromSuperview()
        assetPreview.removeAllConstraints()
        setupAssetPreview()
        constrainAssetPreview()
        setupAssetPreviewBorderWidth()
        setupAssetPreviewCornerRadius()
        regenerateThumbnails()
    }
    
    
    private func setupBorderWidth() {
        trimView.layer.borderWidth = self.borderWidth
    }
    
    private func setupCornerRadius() {
        // setup TrimmerView
        layer.cornerRadius = self.cornerRadius
        
        // setup TrimView
        trimView.layer.cornerRadius = self.cornerRadius
    }
    
    private func setupAssetPreviewBorderWidth() {
        assetPreview.layer.borderWidth = self.assetPreviewBorderWidth
    }
    
    private func setupAssetPreviewCornerRadius() {
        assetPreview.layer.cornerRadius = self.assetPreviewCornerRadius
    }
    
    override func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth + assetPreviewMargin).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth - assetPreviewMargin).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func registerOrientationChangedNotification() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(orientationChanged),
                    name: UIDevice.orientationDidChangeNotification,
                    object: nil)
    }
    
    @objc
    private func orientationChanged() {
        var orientation: UIInterfaceOrientation = .unknown
        if #available(iOS 13.0, *) {
            orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? .portrait
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        
        if isLandscape != orientation.isLandscape {
            regenerateThumbnails()
            setStartTime(tmpStartTime)
            setEndTime(tmpEndTime)
        }
        
        isLandscape = orientation.isLandscape
    }
    
    private func setupTrimmerView() {
        trimView.removeFromSuperview()
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)

        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }

    private func setupHandleView() {
        setupLeftHandleView()
        setupRightHandleView()
    }
    
    private func setupLeftHandleView() {
        leftHandleView.removeFromSuperview()
        leftHandleView.removeAllConstraints()
        leftHandleView.isUserInteractionEnabled = !isHiddenHandle
        leftHandleView.layer.cornerRadius = 4.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)

        leftHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if let customLeftHandleView = customLeftHandleView {
            customLeftHandleView.removeFromSuperview()
            leftHandleView.addSubview(customLeftHandleView)
        } else {
            leftHandleKnobCenter.removeFromSuperview()
            leftHandleKnobCenter.removeAllConstraints()
            leftHandleKnob.removeFromSuperview()
            leftHandleKnob.removeAllConstraints()
            
            leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
            leftHandleView.addSubview(leftHandleKnob)

            leftHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.27).isActive = true
            leftHandleKnob.widthAnchor.constraint(equalToConstant: 6).isActive = true
            leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
            leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
            
            leftHandleKnobCenter.translatesAutoresizingMaskIntoConstraints = false
            leftHandleKnob.addSubview(leftHandleKnobCenter)
            
            leftHandleKnobCenter.heightAnchor.constraint(equalTo: leftHandleKnob.heightAnchor, multiplier: 1).isActive = true
            leftHandleKnobCenter.widthAnchor.constraint(equalToConstant: 3).isActive = true
            leftHandleKnobCenter.centerYAnchor.constraint(equalTo: leftHandleKnob.centerYAnchor).isActive = true
            leftHandleKnobCenter.centerXAnchor.constraint(equalTo: leftHandleKnob.centerXAnchor).isActive = true
        }
    }
    
    private func setupRightHandleView() {
        rightHandleView.removeFromSuperview()
        rightHandleView.removeAllConstraints()
        rightHandleView.isUserInteractionEnabled = !isHiddenHandle
        rightHandleView.layer.cornerRadius = 4.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)

        rightHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if let customRightHandleView = customRightHandleView {
            customRightHandleView.removeFromSuperview()
            rightHandleView.addSubview(customRightHandleView)
        } else {
            rightHandleKnobCenter.removeFromSuperview()
            rightHandleKnobCenter.removeAllConstraints()
            rightHandleKnob.removeFromSuperview()
            rightHandleKnob.removeAllConstraints()
            
            rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
            rightHandleView.addSubview(rightHandleKnob)

            rightHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.27).isActive = true
            rightHandleKnob.widthAnchor.constraint(equalToConstant: 6).isActive = true
            rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
            rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
            
            rightHandleKnobCenter.translatesAutoresizingMaskIntoConstraints = false
            rightHandleKnob.addSubview(rightHandleKnobCenter)
            
            rightHandleKnobCenter.heightAnchor.constraint(equalTo: rightHandleKnob.heightAnchor, multiplier: 1).isActive = true
            rightHandleKnobCenter.widthAnchor.constraint(equalToConstant: 3).isActive = true
            rightHandleKnobCenter.centerYAnchor.constraint(equalTo: rightHandleKnob.centerYAnchor).isActive = true
            rightHandleKnobCenter.centerXAnchor.constraint(equalTo: rightHandleKnob.centerXAnchor).isActive = true
        }
    }
    
    private func setupMaskView() {
        leftMaskView.removeFromSuperview()
        leftMaskView.removeAllConstraints()
        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .black
        leftMaskView.alpha = 0.6
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightMaskView.removeFromSuperview()
        rightMaskView.removeAllConstraints()
        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .white
        rightMaskView.alpha = 0.6
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupPositionBar() {
        positionBar.removeFromSuperview()
        positionBar.removeAllConstraints()
        positionBar.frame = CGRect(x: 0, y: 0, width: positionBarWidth, height: frame.height)
        positionBar.backgroundColor = positionBarColor
        positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = isMovePositionBar
        addSubview(positionBar)

        positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: positionBarWidth).isActive = true
        positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
        positionConstraint?.isActive = true
        
        if let customPositionBar = customPositionBar {
            customPositionBar.removeFromSuperview()
            positionBar.addSubview(customPositionBar)
        }
    }

    private func setupGestures() {
        leftHandleView.gestureRecognizers?.removeAll()
        rightHandleView.gestureRecognizers?.removeAll()
        positionBar.gestureRecognizers?.removeAll()

        if !isHiddenHandle {
            let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
            leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
            let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
            rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
        }
        
        if isMovePositionBar {
            let positionBarGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
            positionBar.addGestureRecognizer(positionBarGestureRecognizer)
        }
    }
    private func updateMainColor() {
        trimView.layer.borderColor = mainColor.cgColor
        assetPreview.layer.borderColor = mainColor.cgColor
        leftHandleView.backgroundColor = mainColor
        rightHandleView.backgroundColor = mainColor
        leftHandleKnobCenter.backgroundColor = mainColor
        rightHandleKnobCenter.backgroundColor = mainColor
    }

    private func updateHandleColor() {
        leftHandleKnob.backgroundColor = handleColor
        rightHandleKnob.backgroundColor = handleColor
    }

    private func updateHandleHidden() {
        leftHandleView.isHidden = isHiddenHandle
        rightHandleView.isHidden = isHiddenHandle
    }
    
    // MARK: - Trim Gestures
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        let isRightGesture = view == rightHandleView
        let isPositionBarGesture = view == positionBar
        
        switch gestureRecognizer.state {
        case .began:
            isMoveTrimmerViewItem = true
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
            } else if isRightGesture {
                currentRightConstraint = rightConstraint!.constant
            } else {
                if isShowTimeLabel {
                    timeLabelView.isHidden = false
                }
                
                currentPositionConstraint = positionConstraint!.constant
            }
            updateSelectedTime(stoppedMoving: false)

        case .changed:
            isMoveTrimmerViewItem = true
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else if isRightGesture {
                updateRightConstraint(with: translation)
            } else {
                updatePositionConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                tmpStartTime = startTime
                seek(to: startTime)
            } else if let endTime = endTime, isRightGesture {
                tmpEndTime = endTime
                seek(to: endTime)
            } else if let currentPlayTime = currentPlayTime {
                tmpCurrentTime = currentPlayTime
                timeLabelView.setTime(currentPlayTime)
            }
            updateSelectedTime(stoppedMoving: isPositionBarGesture)

        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
            if isPositionBarGesture {
                timeLabelView.isHidden = true
            }
            isMoveTrimmerViewItem = false
        default: break
        }
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint?.constant = newConstraint
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        rightConstraint?.constant = newConstraint
    }
    
    private func updatePositionConstraint(with translation: CGPoint) {
        let maxConstraint = assetPreview.frame.size.width - assetPreviewBorderWidth
        let newConstraint = min(max(0, currentPositionConstraint + translation.x), maxConstraint)
        
        print("maxConstraint: \(maxConstraint)")
        print("newConstraint: \(newConstraint)")
        positionConstraint?.constant = newConstraint
        timeLabelConstraint?.constant = newConstraint - timeLabelConstant()
    }

    // MARK: - Asset loading

    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        self.tmpStartTime = .zero
        self.tmpEndTime = newAsset?.duration ?? .zero
        resetHandleViewPosition()
    }

    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0
        layoutIfNeeded()
    }

    // MARK: - Time Equivalence

    /// Move the position bar to the given time.
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {
            let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
                - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            timeLabelConstraint?.constant = normalizedPosition - timeLabelConstant()
            layoutIfNeeded()
        }
    }

    /// The selected start time for the current asset.
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }
    
    public func setStartTime(_ startTime: CMTime) {
        guard let positionX = getPosition(from: startTime) else { return }
        currentLeftConstraint = 0
        updateLeftConstraint(with: CGPoint(x: positionX, y: 0))
        layoutIfNeeded()
    }

    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: endPosition)
    }
    
    public func setEndTime(_ endTime: CMTime) {
        guard let positionX = getPosition(from: endTime) else { return }
        currentRightConstraint = 0
        let maxConstraint = 2 * handleWidth - frame.width
        updateRightConstraint(with: CGPoint(x: positionX + maxConstraint, y: 0))
        layoutIfNeeded()
    }
    
    public var currentPlayTime: CMTime? {
        let playPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: playPosition)
    }
    
    public func setCurrentPlayTime(_ currentPlayTime: CMTime) {
        guard let positionX = getPosition(from: currentPlayTime) else { return }
        currentPositionConstraint = 0
        updatePositionConstraint(with: CGPoint(x: positionX, y: 0))
        layoutIfNeeded()
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }

    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    // MARK: - Scroll View Delegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }
}

class TimeLabelView: UIView {
    
    let timeLabelContainerView = UIView()
    let timeLabel = UILabel()
    let downTriangleView = UIView()
    var constDownTriangleViewCenterX: NSLayoutConstraint?
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setTimeLabel() {
        timeLabelContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        timeLabelContainerView.layer.cornerRadius = 4.0
        timeLabelContainerView.translatesAutoresizingMaskIntoConstraints = false
        timeLabelContainerView.isUserInteractionEnabled = false
        
        addSubview(timeLabelContainerView)
        timeLabelContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        timeLabelContainerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        timeLabelContainerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        timeLabelContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0).isActive = true
        
        timeLabel.backgroundColor = .clear
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.5
        timeLabel.textColor = UIColor(red: (32.0 / 255.0), green: (32.0 / 255.0), blue: (32.0 / 255.0), alpha: 1.0)
        timeLabel.font = UIFont.boldSystemFont(ofSize: 12)
        timeLabel.text = "00:00:00"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.isUserInteractionEnabled = false

        timeLabelContainerView.addSubview(timeLabel)
        timeLabel.leftAnchor.constraint(equalTo: timeLabelContainerView.leftAnchor, constant: 4).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: timeLabelContainerView.rightAnchor, constant: -4).isActive = true
        timeLabel.topAnchor.constraint(equalTo: timeLabelContainerView.topAnchor, constant: 1).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: timeLabelContainerView.bottomAnchor, constant: -1).isActive = true
    }
    
    private func setDownTriangle() {
        let width: CGFloat = 8.0
        let height: CGFloat = 6.0
        let path = CGMutablePath()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x:width/2, y: width/2))
        path.addLine(to: CGPoint(x:height, y:0))
        path.addLine(to: CGPoint(x:0, y:0))

        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = UIColor.white.withAlphaComponent(0.8).cgColor
        downTriangleView.frame = CGRect(origin: .zero, size: .init(width: width, height: height))
        downTriangleView.layer.insertSublayer(shape, at: 0)
        downTriangleView.translatesAutoresizingMaskIntoConstraints = false
        downTriangleView.isUserInteractionEnabled = false
        
        addSubview(downTriangleView)
        downTriangleView.widthAnchor.constraint(equalToConstant: width).isActive = true
        downTriangleView.heightAnchor.constraint(equalToConstant: height).isActive = true
        downTriangleView.topAnchor.constraint(equalTo: timeLabelContainerView.bottomAnchor, constant: 0).isActive = true
        constDownTriangleViewCenterX = downTriangleView.centerXAnchor.constraint(equalTo: centerXAnchor)
        constDownTriangleViewCenterX?.isActive = true
    }
    
    private func setupSubviews() {
        backgroundColor = .clear
        setTimeLabel()
        setDownTriangle()
    }
    
    func setTime(_ time: CMTime) {
        let secs = Int(time.seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        timeLabel.text = String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
    }
}
