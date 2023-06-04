//
//  BrowseImageView.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit
import JPBlurView

class BrowseImageView: UIView {
    let blurView = JPBlurAnimationView(effectStyle: .systemThinMaterialDark, intensity: 0, frame: UIScreen.main.bounds)
    let imageView = UIImageView()
    weak var cell: WaterfallCell? = nil
    
    var sourceFrame: CGRect = .zero
    var targetFrame: CGRect = .zero
    
    var screenCenterY: CGFloat { targetFrame.midY }
    
    var isRecover = false
    var isPaning = false
    var currentCenterY: CGFloat = 0
    var beginPosition: CGPoint = .zero
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        addSubview(blurView)
        addSubview(imageView)
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction(_:))))
        imageView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panAction(_:))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetImageViewAnchorPoint(_ anchorPoint: CGPoint) {
        let position = CGPoint(x: targetFrame.origin.x + imageView.bounds.width * anchorPoint.x,
                               y: targetFrame.origin.y + imageView.bounds.height * anchorPoint.y)
        CATransaction.execute {
            self.imageView.layer.anchorPoint = anchorPoint
            self.imageView.layer.position = position
        }
    }
}

// MARK: - Show / Hide
extension BrowseImageView {
    static func show(from cell: WaterfallCell) {
        guard let window = cell.window, let model = cell.model else {
            return
        }
        
        let safeAreaInsets = window.safeAreaInsets
        let maxFrame = CGRect(x: safeAreaInsets.left,
                              y: safeAreaInsets.top,
                              width: window.bounds.width - safeAreaInsets.left - safeAreaInsets.right,
                              height: window.bounds.height - safeAreaInsets.top - safeAreaInsets.bottom)
        
        let sourceFrame = cell.convert(cell.bounds, to: window)
        
        var targetSize = CGSize(width: maxFrame.width,
                                height: (model.cellSize.height / model.cellSize.width) * maxFrame.width)
        if targetSize.height > maxFrame.height {
            targetSize = CGSize(width: (model.cellSize.width / model.cellSize.height) * maxFrame.height,
                                height: maxFrame.height)
        }
        let targetFrame = CGRect(origin: CGPoint(x: maxFrame.origin.x + (maxFrame.width - targetSize.width) * 0.5,
                                                 y: maxFrame.origin.y + (maxFrame.height - targetSize.height) * 0.5),
                                 size: targetSize)
        
        let browseImageView = BrowseImageView()
        browseImageView.sourceFrame = sourceFrame
        browseImageView.targetFrame = targetFrame
        browseImageView.cell = cell
        window.addSubview(browseImageView)
        
        browseImageView.show()
    }
    
    func show() {
        guard let cell = self.cell, let model = cell.model else {
            removeFromSuperview()
            return
        }
        let image = UIImage.girlImage(model.imageIndex)
        
        imageView.image = cell.imgView.image
        imageView.layer.cornerRadius = cell.imgView.layer.cornerRadius
        imageView.layer.masksToBounds = imageView.layer.cornerRadius > 0
        imageView.frame = sourceFrame
        imageView.isUserInteractionEnabled = false
        
        // next runloop to show
        DispatchQueue.main.async {
            cell.isHidden = true
            
            self.blurView.setIntensity(to: 1, duration: 0.5)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.imageView.layer.cornerRadius = 0
                self.imageView.frame = self.targetFrame
                self.imageView.image = image
            } completion: { _ in
                self.imageView.isUserInteractionEnabled = true
            }
        }
    }
    
    func hide() {
        imageView.isUserInteractionEnabled = false
        
        blurView.setIntensity(to: 0, duration: 0.5)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.imageView.layer.cornerRadius = self.cell?.imgView.layer.cornerRadius ?? 0
            self.imageView.frame = self.sourceFrame
        } completion: { _ in
            self.cell?.isHidden = false
            
            UIView.animate(withDuration: 0.2) {
                self.imageView.alpha = 0
            } completion: { _ in
                self.removeFromSuperview()
            }
        }
    }
}

// MARK: - Gesture Handle
extension BrowseImageView {
    @objc func tapAction(_ tapGR: UITapGestureRecognizer) {
        hide()
    }
    
    @objc func panAction(_ panGR: UIPanGestureRecognizer) {
        let translation = panGR.translation(in: imageView)
        panGR.setTranslation(.zero, in: imageView)
        
        switch panGR.state {
        case .began:
            isRecover = true
            isPaning = true
            
            let velocity = panGR.velocity(in: imageView)
            let isVerticalGesture = velocity.y > 0 && (abs(velocity.y) > abs(velocity.x))
            if !isVerticalGesture {
                isPaning = false
                return
            }
            
            currentCenterY = screenCenterY
            beginPosition = panGR.location(in: self)
            
            let anchorPoint = CGPoint(x: (beginPosition.x - targetFrame.origin.x) / imageView.bounds.width,
                                      y: (beginPosition.y - targetFrame.origin.y) / imageView.bounds.height)
            resetImageViewAnchorPoint(anchorPoint)
            
        case .changed:
            guard isPaning else { return }
            
            currentCenterY += translation.y
            
            var sizeScale: CGFloat = 1
            var blurIntensity: CGFloat = 1
            if (currentCenterY > screenCenterY) {
                let currMargin = currentCenterY - screenCenterY
                
                let diffMargin = screenCenterY * 0.5
                isRecover = currMargin <= diffMargin
                
                var scale = currMargin / screenCenterY
                if scale > 1 { scale = 1 }
                
                blurIntensity = 1 - scale
                
                // 1 - 0.4 = 0.6 为最大缩放比例
                sizeScale = (imageView.bounds.width * (1 - scale * 0.4)) / imageView.frame.width;
            } else {
                isRecover = true
            }
            
            blurView.intensity = blurIntensity
            
            let transform = CATransform3DScale(imageView.layer.transform, sizeScale, sizeScale, 1)
            let position = panGR.location(in: self)
            CATransaction.execute {
                self.imageView.layer.transform = transform
                self.imageView.layer.position = position
            }
            
        case .ended, .cancelled, .failed:
            guard isPaning else {
                blurView.intensity = 1
                resetImageViewAnchorPoint(CGPoint(x: 0.5, y: 0.5))
                return
            }
            
            isPaning = false
            
            let velocity = panGR.velocity(in: imageView)
            let isHide = velocity.y > 1000 || !isRecover
            if isHide {
                hide()
                return
            }
            
            blurView.setIntensity(to: 1, duration: 0.3)
            
            UIView.animate(withDuration: 0.3) {
                self.imageView.layer.transform = CATransform3DIdentity
                self.imageView.layer.position = self.beginPosition
            } completion: { _ in
                self.resetImageViewAnchorPoint(CGPoint(x: 0.5, y: 0.5))
            }
            
        default:
            break
        }
    }
}
