//
//  JPBlurAnimationView.swift
//  JPBlurView
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit
import pop

public class JPBlurAnimationView: JPBlurView {
    private lazy var executor = AnimationExecutor()
    
    public override init(effectStyle: UIBlurEffect.Style, intensity: CGFloat = 1, frame: CGRect = .zero) {
        super.init(effectStyle: effectStyle, intensity: intensity, frame: frame)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(didEnterBackgroundHandle),
                         name: UIApplication.didEnterBackgroundNotification,
                         object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
//        print("BlurAnimationView deinit")
    }
}

// MARK: - API
public extension JPBlurAnimationView {
    /// 便捷设置模糊度
    /// - Parameters:
    ///   - intensity: 模糊度
    ///   - animated: 是否带有动画效果
    func setIntensity(_ intensity: CGFloat, animated: Bool) {
        setIntensity(to: intensity, duration: animated ? 0.3 : 0)
    }
    
    /// 设置模糊度
    /// - Parameters:
    ///   - from: 起始模糊度（为`nil`则当前模糊度）
    ///   - to: 目标模糊度
    ///   - duration: 动画时长（小于等于`0`则不带动画效果）
    ///   - timingFunctionName: 动画曲线
    func setIntensity(from: CGFloat? = nil,
                      to: CGFloat,
                      duration: TimeInterval,
                      timingFunctionName: CAMediaTimingFunctionName? = nil) {
        executor.start(fromValue: from ?? intensity,
                       toValue: to,
                       duration: duration,
                       timingFunctionName: timingFunctionName) { [weak self] value in
            self?.intensity = value
        }
    }
    
    /// 停止动画（停止后模糊度为动画停止那一刻的数值）
    func stopAnimation() {
        _ = executor.stop()
    }
}

// MARK: - 监听通知
private extension JPBlurAnimationView {
    @objc func didEnterBackgroundHandle() {
        guard let intensity = executor.stop() else { return }
        self.intensity = intensity
    }
}

// MARK: - 私有类
private extension JPBlurAnimationView {
    class AnimationExecutor: NSObject {
        static let animKey = "JPAnimation"
        static let propKey = "JPProperty"
        
        func start(fromValue: CGFloat,
                   toValue: CGFloat,
                   duration: TimeInterval,
                   timingFunctionName: CAMediaTimingFunctionName?,
                   valueDidChangedHandler: @escaping (_ value: CGFloat) -> Void) {
            pop_removeAnimation(forKey: Self.animKey)
            
            guard duration > 0, fromValue != toValue else {
                valueDidChangedHandler(toValue)
                return
            }
            
            let animation = POPBasicAnimation()
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.duration = duration
            if let timingFunctionName = timingFunctionName {
                animation.timingFunction = CAMediaTimingFunction(name: timingFunctionName)
            }
            
            animation.property = POPAnimatableProperty.property(withName: Self.propKey) { prop in
                prop?.writeBlock = { (_, values) in
                    guard let values = values else { return }
                    let value = values[0]
                    valueDidChangedHandler(value)
                }
            } as? POPAnimatableProperty
            
            pop_add(animation, forKey: Self.animKey)
        }
        
        func stop() -> CGFloat? {
            let animation = pop_animation(forKey: Self.animKey) as? POPBasicAnimation
            pop_removeAnimation(forKey: Self.animKey)
            return animation?.toValue as? CGFloat
        }
        
//        deinit {
//            print("AnimationExecutor deinit")
//        }
    }
}

