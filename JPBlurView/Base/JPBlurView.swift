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
    private var animator: UIViewPropertyAnimator!
    private var _intensity: CGFloat = 0
    
    /// 模糊度
    public var intensity: CGFloat {
        set {
            _intensity = (newValue > 1) ? 1 : (newValue < 0 ? 0 : newValue)
            animator.fractionComplete = _intensity
        }
        get { _intensity }
    }
    
    public init(effectStyle: UIBlurEffect.Style, intensity: CGFloat = 1, frame: CGRect = .zero) {
        self.effect = UIBlurEffect(style: effectStyle)
        super.init(frame: frame)
        _intensity = (intensity > 1) ? 1 : (intensity < 0 ? 0 : intensity)
        setupEffectView()
        resetAnimator()
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
        // 如果有【没有开启】或【还没结束】的动画，必须在退出页面时让动画结束，否则会崩溃！
        animator.stopAnimation(true)
//        print("BlurView deinit")
    }
}

// MARK: - 监听通知
private extension JPBlurView {
    @objc func willEnterForegroundHandle() {
        // App一旦进入后台模式animator就会失效（挂起时不会），返回前台时重新设置一下
        guard animator.state != .active else { return }
        animator.stopAnimation(true)
        resetAnimator()
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
    
    func resetAnimator() {
        effectView.effect = nil
        animator = UIViewPropertyAnimator(duration: 0, curve: .linear, animations: { [weak self] in
            self?.effectView.effect = self?.effect
        })
        animator.fractionComplete = intensity
    }
}
