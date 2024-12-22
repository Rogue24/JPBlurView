//
//  Extensions.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

private let ColorSpace = CGColorSpaceCreateDeviceRGB()

extension UIImage {
    static func girlImage(_ index: Int) -> UIImage {
        UIImage(contentsOfFile: Bundle.main.path(forResource: "girl_\(index)", ofType: "jpg")!)!
    }
    
    static var randomGirlImage: UIImage {
        girlImage(Int.random(in: 1...16))
    }
    
    static func decodeImage(_ image: UIImage, resize: CGSize) -> UIImage? {
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

extension CATransaction {
    static func execute(_ action: () -> ()) {
        begin()
        setDisableActions(true)
        action()
        commit()
    }
}
