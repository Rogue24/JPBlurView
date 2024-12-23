//
//  WaterfallStore.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

enum WaterfallStore {
    private(set) static var models: [WaterfallModel] = []
    static var loadDone: (() -> Void)?
    
    private static var isLoaded = false
    private static var isLoading = false
    
    static func loadData() {
        guard !isLoaded else {
            loadDone?()
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        let group = DispatchGroup()
        let locker = DispatchSemaphore(value: 1)
        
        let maxWidth = WaterfallCell.maxWidth
        let scale: CGFloat = 2//UIScreen.main.scale
        
        for i in 1...16 {
            DispatchQueue.global().async(group: group) {
                let image = UIImage.girlImage(i)
                
                let cellSize = CGSize(width: maxWidth, height: (image.size.height / image.size.width) * maxWidth)
                let resize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
                
                guard let decodeImg = UIImage.decodeImage(image, resize: resize) else { return }
                let model = WaterfallModel(image: decodeImg,
                                           imageIndex: i,
                                           cellSize: cellSize)
                
                locker.wait()
                models.append(model)
                locker.signal()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            isLoaded = true
            loadDone?()
        }
    }
}
