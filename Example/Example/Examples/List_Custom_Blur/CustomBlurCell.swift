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
    private var blurView: JPBlurView?
    private let intensityLabel = UILabel()
    
    var model: CustomBlurModel? {
        didSet {
            guard let model = self.model else { return }
            imgView.image = model.image
            
            if let blurView {
                // 需要在下一个runloop才重置，否则会受系统动画的影响（collectionView.reloadSections），
                // 使其内部的animator开启动画并完成 -> 毛玻璃100%
                DispatchQueue.main.async {
                    blurView.resetEffect(model.intensity)
                }
                return
            }
            
            guard model.intensity > 0 else { return }
            
            let blurView = JPBlurView(effectStyle: .dark, intensity: model.intensity)
            contentView.insertSubview(blurView, aboveSubview: imgView)
            blurView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.blurView = blurView
            contentView.layoutIfNeeded()
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
