//
//  WaterfallCell.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

class WaterfallCell: UICollectionViewCell {
    static let maxWidth = (UIScreen.main.bounds.width - 15) / 3
    let imgView = UIImageView()
    
    var model: WaterfallModel? {
        didSet {
            guard let model = self.model else { return }
            imgView.image = model.image
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imgView.layer.cornerRadius = 4
        imgView.layer.masksToBounds = true
        imgView.backgroundColor = .lightGray
        
        imgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imgView)
        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
