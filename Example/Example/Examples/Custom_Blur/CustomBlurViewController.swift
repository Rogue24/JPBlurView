//
//  CustomBlurViewController.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit
import JPBlurView
import SnapKit

class CustomBlurViewController: UIViewController {
    private let blurView = JPBlurAnimationView(effectStyle: .systemThinMaterialDark, intensity: 0)
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Example.customBlur.title
        
        imageView.image = UIImage.randomGirlImage
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, aboveSubview: imageView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        blurView.intensity = CGFloat(sender.value)
    }
    
    @IBAction func animateSetValue(_ sender: UIButton) {
        let intensity = CGFloat(sender.tag) / 100
        blurView.setIntensity(intensity, animated: true)
        slider.setValue(Float(intensity), animated: true)
    }
}
