//
//  Extensions.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

extension UIImage {
    static func girlImage(_ index: Int) -> UIImage {
        UIImage(contentsOfFile: Bundle.main.path(forResource: "girl_\(index)", ofType: "jpg")!)!
    }
    
    static var randomGirlImage: UIImage {
        girlImage(Int.random(in: 1...16))
    }
}

extension CATransaction {
    static func execute(_ action: () -> ()) {
        begin()
        setDisableActions(true)
        action()
        commit()
    }
}
