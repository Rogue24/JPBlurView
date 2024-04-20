//
//  WaterfallViewController.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

class WaterfallViewController: UIViewController {
    lazy var collectionView: UICollectionView = {
        let waterfallLayout = WaterfallLayout()
        waterfallLayout.delegate = self
        waterfallLayout.asyncUpdateLayout(itemTotal: models.count) { [weak self] index, itemWidth in
            guard let self = self else { return 1 }
            let model = self.models[index]
            return model.cellSize.height
        } completion: { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 1) {
                self.collectionView.performBatchUpdates {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
        
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: waterfallLayout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WaterfallCell.self, forCellWithReuseIdentifier: "cell")
        
        return collectionView
    }()
    
    var isAppear: Bool = false
    
    var models: [WaterfallModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interactive & Animable Blur"
        view.backgroundColor = .systemGroupedBackground
        view.insertSubview(collectionView, at: 0)
        
        WaterfallStore.loadDone = { [weak self] in
            guard let self = self else { return }
            self.models = WaterfallStore.models.shuffled()
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 1) {
                self.collectionView.performBatchUpdates {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isAppear else { return }
        isAppear = true
        WaterfallStore.loadData()
    }
    
    deinit {
        WaterfallStore.loadDone = nil
    }
}

extension WaterfallViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WaterfallCell
        cell.model = models[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.setContentOffset(collectionView.contentOffset, animated: true)
        let cell = collectionView.cellForItem(at: indexPath) as! WaterfallCell
        BrowseImageView.show(from: cell)
    }
}

extension WaterfallViewController: WaterfallLayoutDelegate {
    func waterfallLayout(_ waterfallLayout: WaterfallLayout, heightForItemAtIndex index: Int, itemWidth: CGFloat) -> CGFloat {
        let model = models[index]
        return model.cellSize.height
    }
    
    func colCountInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> Int { 3 }
    
    func colMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat { 5 }
    
    func rowMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat { 5 }
    
    func edgeInsetsInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> UIEdgeInsets {
        var safeAreaInsets: UIEdgeInsets = UIApplication.shared.delegate?.window??.safeAreaInsets ?? .zero
        safeAreaInsets.top += 44 + 5
        safeAreaInsets.left += 5
        safeAreaInsets.bottom += 5
        safeAreaInsets.right += 5
        return safeAreaInsets
    }
}
