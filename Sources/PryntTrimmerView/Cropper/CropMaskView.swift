//
//  CropMaskView.swift
//  PryntTrimmerView
//
//  Created by Henry on 10/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class CropMaskView: UIView {
    let cropBoxView = UIView()
    let frameView = UIView()
    let maskLayer = CAShapeLayer()
    let frameLayer = CAShapeLayer()
    
    private let lineWidth: CGFloat = 4.0
    private var cropFrame = CGRect.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.opacity = 1.0
        
        frameLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        frameLayer.fillColor = UIColor.clear.cgColor
        
        frameView.layer.addSublayer(frameLayer)
        cropBoxView.layer.mask = maskLayer
        
        cropBoxView.translatesAutoresizingMaskIntoConstraints = false
        cropBoxView.backgroundColor = UIColor.white
        
        addSubview(cropBoxView)
        addSubview(frameView)
        
        cropBoxView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        cropBoxView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        cropBoxView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cropBoxView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(rect: bounds)
        let framePath = UIBezierPath(rect: cropFrame)
        path.append(framePath)
        path.usesEvenOddFillRule = true
        maskLayer.path = path.cgPath

        framePath.lineWidth = lineWidth
        frameLayer.path = framePath.cgPath
        
        for gridView in subviews where gridView is GridView {
            gridView.removeFromSuperview()
        }
        
        let gridView = GridView(frame: cropFrame)
        gridView.backgroundColor = .clear
        addSubview(gridView)
    }
    
    func setCropFrame(_ frame: CGRect, animated: Bool) {
        cropFrame = frame
        guard animated else {
            setNeedsLayout()
            return
        }
        
        let (path, framePath) = getPaths(with: cropFrame)
        
        CATransaction.begin()
        
        let animation = getPathAnimation(with: path)
        maskLayer.path = maskLayer.presentation()?.path
        frameLayer.path = frameLayer.presentation()?.path
        
        maskLayer.removeAnimation(forKey: "maskPath")
        maskLayer.add(animation, forKey: "maskPath")
        
        animation.toValue = framePath
        frameLayer.removeAnimation(forKey: "framePath")
        frameLayer.add(animation, forKey: "framePath")
        CATransaction.commit()
    }
    
    private func getPaths(with cropFrame: CGRect) -> (path: CGPath, framePath: CGPath) {
        let path = UIBezierPath(rect: bounds)
        let framePath = UIBezierPath(rect: cropFrame)
        framePath.lineWidth = lineWidth
        path.append(framePath)
        path.usesEvenOddFillRule = true
        
        return (path.cgPath, framePath.cgPath)
    }
    
    private func getPathAnimation(with path: CGPath) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "path")
        animation.toValue = path
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fillMode = CAMediaTimingFillMode.both
        animation.isRemovedOnCompletion = false
        
        return animation
    }
}

class GridView: UIView {
    private var rect: CGRect = .init()
    
    private var oneEdgeLength: CGFloat {
        rect.maxX / 18
    }
    
    override func draw(_ rect: CGRect) {
        self.rect = rect
        
        drawGridStroke()
        drawLeftTop()
        drawLeftBottom()
        drawRightBottom()
        drawRightTop()
    }
    
    private func getFirstPoint(_ point: CGFloat) -> CGFloat {
        point / 3
    }
    
    private func getSecondPoint(_ point: CGFloat) -> CGFloat {
        point * 2 / 3
    }
    
    private func drawLeftTop() {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: rect.minX + oneEdgeLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + oneEdgeLength))
        
        path.lineWidth = 2
        UIColor.white.setStroke()
        path.stroke()
    }
    
    private func drawLeftBottom() {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - oneEdgeLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + oneEdgeLength, y: rect.maxY))
        
        path.lineWidth = 2
        UIColor.white.setStroke()
        path.stroke()
    }
    
    private func drawRightBottom() {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: rect.maxX - oneEdgeLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - oneEdgeLength))
        
        path.lineWidth = 2
        UIColor.white.setStroke()
        path.stroke()
    }
    
    private func drawRightTop() {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY + oneEdgeLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - oneEdgeLength, y: rect.minY))
        
        path.lineWidth = 2
        UIColor.white.setStroke()
        path.stroke()
    }
    
    private func drawGridStroke() {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: getFirstPoint(rect.maxX), y: rect.minY))
        path.addLine(to: CGPoint(x: getFirstPoint(rect.maxX), y: rect.maxY))
        path.close()
        
        path.move(to: CGPoint(x: getSecondPoint(rect.maxX), y: rect.minY))
        path.addLine(to: CGPoint(x: getSecondPoint(rect.maxX), y: rect.maxY))
        path.close()
        
        path.move(to: CGPoint(x: rect.minX, y: getFirstPoint(rect.maxY)))
        path.addLine(to: CGPoint(x: rect.maxX, y: getFirstPoint(rect.maxY)))
        path.close()
        
        path.move(to: CGPoint(x: rect.minX, y: getSecondPoint(rect.maxY)))
        path.addLine(to: CGPoint(x: rect.maxX, y: getSecondPoint(rect.maxY)))
        path.close()
        
        UIColor.white.withAlphaComponent(0.5).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}
