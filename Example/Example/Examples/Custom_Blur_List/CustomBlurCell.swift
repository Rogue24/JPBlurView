//
//  CustomBlurCell.swift
//  Example
//
//  Created by aa on 2024/12/22.
//

import UIKit
import SnapKit
import JPBlurView

class CustomBlurCell: UICollectionViewCell {
    private let imgView = UIImageView()
    private let blurView = JPBlurView(effectStyle: .dark, intensity: 0)
    private let intensityLabel = UILabel()
    
    var model: CustomBlurModel? {
        didSet {
            intensityLabel.text = String(format: "Blur %.0f%%", (model?.intensity ?? 0) * 100)
            
            imgView.image = model?.image
            
            // 需要在下一个runloop才能重置，否则会受到系统动画的影响（collectionView.reloadSections）导致失效，
            // 使其内部的animator开启动画并完成 -> blur XX%
            DispatchQueue.main.async {
                self.blurView.resetEffect(self.model?.intensity)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .lightGray
        
        imgView.contentMode = .scaleAspectFill
        contentView.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        intensityLabel.font = .systemFont(ofSize: 12)
        intensityLabel.textColor = .white
        intensityLabel.layer.shadowColor = UIColor.black.cgColor
        intensityLabel.layer.shadowOpacity = 0.8
        intensityLabel.layer.shadowOffset = CGSizeZero
        intensityLabel.layer.shadowRadius = 1
        contentView.addSubview(intensityLabel)
        intensityLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.trailing.equalToSuperview().offset(-5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
