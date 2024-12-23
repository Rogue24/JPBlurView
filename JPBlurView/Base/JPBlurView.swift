//
//  JPBlurView.swift
//  JPBlurView
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

public class JPBlurView: UIView {
    private let effect: UIBlurEffect
    private let effectView = UIVisualEffectView(effect: nil)
    private var animator: UIViewPropertyAnimator?
    private var _intensity: CGFloat = 0
    
    /// 模糊度
    public var intensity: CGFloat {
        get { _intensity }
        set {
            _intensity = (newValue > 1) ? 1 : (newValue < 0 ? 0 : newValue)
            if let animator, animator.state == .active {
                animator.fractionComplete = _intensity
            } else {
                resetEffect()
            }
        }
    }
    
    /// 重置模糊效果
    /// - Parameters:
    ///   - intensity: 重置的模糊度，取值范围[0, 1]，默认为`nil`，表示不改变当前模糊度
    /// - Note: 在某些特定的场景，例如App前后台切换和`UITableViewCell/UICollectionViewCell`的复用，`UIViewPropertyAnimator`会直接失效。其中App前后台切换已内部处理，其他情况内部无法完全解决，为此提供该方法给外部调用。
    public func resetEffect(_ intensity: CGFloat? = nil) {
        if let animator {
            animator.stopAnimation(true)
        }
        effectView.effect = nil
        
        if let intensity {
            _intensity = (intensity > 1) ? 1 : (intensity < 0 ? 0 : intensity)
        }
        
        let animator = UIViewPropertyAnimator(duration: 0, curve: .linear, animations: { [weak self] in
            self?.effectView.effect = self?.effect
        })
        if #available(iOS 11.0, *) {
            // 设置`animator`在完成时自动暂停而不是转换到非活动状态
            // 可以防止动画结束后被清理（App进入后台模式时会清理）
            animator.pausesOnCompletion = true
        }
        animator.fractionComplete = _intensity
        
        self.animator = animator
    }
    
    public init(effectStyle: UIBlurEffect.Style, intensity: CGFloat = 1, frame: CGRect = .zero) {
        self.effect = UIBlurEffect(style: effectStyle)
        super.init(frame: frame)
        setupEffectView()
        resetEffect(intensity)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(willEnterForegroundHandle),
                         name: UIApplication.willEnterForegroundNotification,
                         object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // 📢 如果有【没有开启】或【还没结束】的动画，必须在退出页面时让动画结束，否则会崩溃！
        animator?.stopAnimation(true)
    }
}

// MARK: - 监听通知
private extension JPBlurView {
    /// App即将进入前台
    ///
    /// `iOS11之前`
    /// - App一旦进入后台模式，`animator`就会失效（挂起时不会）
    /// - `state`会变为`inactive`
    /// - 解决方案：返回前台时重置`animator`
    ///
    /// `iOS11之后`
    /// - 设置`animator.pausesOnCompletion = true`，App进入后台模式`animator`也不会失效
    /// - `state`保持为`active`
    /// - 不再需要重置`animator`
    ///
    @objc func willEnterForegroundHandle() {
        if let animator, animator.state == .active {
            return
        }
        resetEffect()
    }
}

// MARK: - 私有实现
private extension JPBlurView {
    func setupEffectView() {
        effectView.isUserInteractionEnabled = false
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
