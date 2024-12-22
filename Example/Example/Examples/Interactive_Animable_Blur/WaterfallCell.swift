//
//  WaterfallCell.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit
import SnapKit

class WaterfallCell: UICollectionViewCell {
    static let maxWidth = (UIScreen.main.bounds.width - 10 - 5 - 5 - 10) / 3
    
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
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
