//
//  WaterfallModel.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

struct WaterfallModel: Identifiable {
    let id = UUID()
    let image: UIImage
    let imageIndex: Int
    let cellSize: CGSize
}
