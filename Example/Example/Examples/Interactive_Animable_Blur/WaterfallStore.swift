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
        
        for i in 1...16 {
            DispatchQueue.global().async(group: group) {
                let image = UIImage.girlImage(i)
                let cellSize = CGSize(width: maxWidth, height: (image.size.height / image.size.width) * maxWidth)
                let resize = CGSize(width: cellSize.width * 2, height: cellSize.height * 2)
                
                guard let decodeImg = decodeImage(image, resize: resize) else { return }
                let model = WaterfallModel(image: decodeImg, imageIndex: i, cellSize: cellSize)
                
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
    
    private static func decodeImage(_ image: UIImage, resize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        var size = resize
        if resize.width > CGFloat(cgImage.width) {
            size = CGSize(width: cgImage.width, height: cgImage.height)
        }
        
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapRawValue |= CGImageAlphaInfo.noneSkipFirst.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: ColorSpace,
                                      bitmapInfo: bitmapRawValue) else { return nil }
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        let decodeImg = context.makeImage()
        return decodeImg.map { UIImage(cgImage: $0) } ?? nil
    }
}

let ColorSpace = CGColorSpaceCreateDeviceRGB()
