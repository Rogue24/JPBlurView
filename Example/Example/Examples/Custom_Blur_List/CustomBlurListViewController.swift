//
//  CustomBlurListViewController.swift
//  Example
//
//  Created by aa on 2024/12/22.
//

import UIKit

class CustomBlurListViewController: UIViewController {
    static let cellSize: CGSize = {
        let cellW = (UIScreen.main.bounds.width - 10 - 5 - 5 - 10) / 3
        let cellH = cellW * (5.0 / 3.0)
        return CGSize(width: cellW, height: cellH)
    }()
    
    private let describeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.textColor = .label
        label.numberOfLines = 0
        
        if let language = Locale.preferredLanguages.first, language.hasPrefix("zh") {
            label.text = """
            📢📢📢 在 UITableViewCell/UICollectionViewCell 上使用自定义毛玻璃，模糊效果会不稳定（反复滑动会有毛玻璃消失的情况）。
            - 经调试发现，是苹果的复用机制会让 UIViewPropertyAnimator 直接失效。
            - 目前还没找到完美解决的方法，只能提供一个重置模糊效果的方法，在复用Cell时对其进行重置（具体重置操作可以参考 CustomBlurCell 的 setModel 方法）。
            
            点击Cell，调整模糊度
            - 点击右上角的+/-，切换增减模式
            """
        } else {
            label.text = """
            📢📢📢 Using a custom blur effect on UITableViewCell/UICollectionViewCell can lead to instability (the blur effect may disappear after repeated scrolling).
            - Debugging revealed that Apple's reuse mechanism causes UIViewPropertyAnimator to become invalid.
            - A perfect solution has not been found yet. Currently, the only workaround is to reset the blur effect when reusing the cell. For details on the reset process, refer to the `setModel` method in `CustomBlurCell`.
            
            Tap the cell to adjust the blur intensity
            - Tap the +/- button in the top-right corner to switch between increase and decrease modes
            """
        }
        
        let maxWidth = UIScreen.main.bounds.width - 10 - 10
        label.frame.size = CGSize(width: maxWidth, height: label.sizeThatFits(CGSize(width: maxWidth, height: 999)).height)
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = Self.cellSize
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        var safeAreaInsets: UIEdgeInsets = UIApplication.shared.delegate?.window??.safeAreaInsets ?? .zero
        
        describeLabel.frame.origin.x = 10
        describeLabel.frame.origin.y = safeAreaInsets.top + 44
        
        safeAreaInsets.top = describeLabel.frame.maxY + 10
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
        
        collectionView.addSubview(describeLabel)
        
        return collectionView
    }()
    
    private var isAppear: Bool = false
    private var isSubtract: Bool = false
    
    private var models: [CustomBlurModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Example.customBlurList.title
        view.backgroundColor = .systemGroupedBackground
        view.insertSubview(collectionView, at: 0)
        
        let segmentedControl = UISegmentedControl(items: ["+", "-"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isAppear else { return }
        isAppear = true
        loadData()
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
        
        if isSubtract {
            model.intensity -= 0.01
            if model.intensity < 0 {
                model.intensity = 0
            }
        } else {
            model.intensity += 0.01
            if model.intensity > 1 {
                model.intensity = 1
            }
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! CustomBlurCell
        cell.model = model
    }
}

private extension CustomBlurListViewController {
    func loadData() {
        let group = DispatchGroup()
        let locker = DispatchSemaphore(value: 1)
        
        let width = Self.cellSize.width * 2//UIScreen.main.scale
        var models: [CustomBlurModel] = []
        
        for _ in 0..<30 {
            DispatchQueue.global().async(group: group) {
                let image = UIImage.girlImage(Int.random(in: 1...16))
                let height = width * image.size.height / image.size.width
                let resize = CGSize(width: width, height: height)
                
                guard let decodeImg = UIImage.decodeImage(image, resize: resize) else { return }
                let model = CustomBlurModel(image: decodeImg)
                model.intensity = CGFloat(Int.random(in: 0...10)) / 10
                
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
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        isSubtract = sender.selectedSegmentIndex == 1
    }
}
