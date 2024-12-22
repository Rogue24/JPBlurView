//
//  CustomBlurListViewController.swift
//  Example
//
//  Created by aa on 2024/12/22.
//

import UIKit

class CustomBlurListViewController: UIViewController {
    static let cellSize: CGSize = {
        let cellW = (UIScreen.main.bounds.width - 30) / 3
        let cellH = cellW * (5.0 / 3.0)
        return CGSize(width: cellW, height: cellH)
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = Self.cellSize
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        var safeAreaInsets: UIEdgeInsets = UIApplication.shared.delegate?.window??.safeAreaInsets ?? .zero
        safeAreaInsets.top += 44 + 5
        safeAreaInsets.left += 10
        safeAreaInsets.bottom += 5
        safeAreaInsets.right += 10
        layout.sectionInset = safeAreaInsets
        
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomBlurCell.self, forCellWithReuseIdentifier: "cell")
        
        return collectionView
    }()
    
    var isAppear: Bool = false
    
    var models: [CustomBlurModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interactive & Animable Blur"
        view.backgroundColor = .systemGroupedBackground
        view.insertSubview(collectionView, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isAppear else { return }
        isAppear = true
        
        let group = DispatchGroup()
        let locker = DispatchSemaphore(value: 1)
        var models: [CustomBlurModel] = []
        
        for _ in 0...33 {
            DispatchQueue.global().async(group: group) {
                let image = UIImage.girlImage(Int.random(in: 1...16))
                let width = Self.cellSize.width * 2
                let height = width * image.size.height / image.size.width
                let resize = CGSize(width: width, height: height)
                guard let decodeImg = UIImage.decodeImage(image, resize: resize) else { return }
                let model = CustomBlurModel(image: decodeImg)
                
                locker.wait()
                models.append(model)
                locker.signal()
            }
        }
        
        group.notify(queue: .main) {
            self.models = models
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 1) {
                self.collectionView.performBatchUpdates {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
}

extension CustomBlurListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CustomBlurCell
        cell.model = models[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = models[indexPath.item]
        model.intensity += 0.01
        
        let cell = collectionView.cellForItem(at: indexPath) as! CustomBlurCell
        cell.model = model
    }
}
