//
//  CustomBlurViewController.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit
import JPBlurView

class CustomBlurViewController: UIViewController {
    let blurView = JPBlurAnimationView(effectStyle: .systemThinMaterialDark, intensity: 0)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom Blur"
        
        imageView.image = UIImage.randomGirlImage
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, aboveSubview: imageView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
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
