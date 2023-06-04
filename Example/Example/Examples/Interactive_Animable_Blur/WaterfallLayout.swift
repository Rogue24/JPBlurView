//
//  WaterfallLayout.swift
//  Example
//
//  Created by 周健平 on 2023/6/4.
//

import UIKit

@objc
protocol WaterfallLayoutDelegate: NSObjectProtocol {
    /// 根据给出的宽度计算出item高度
    func waterfallLayout(_ waterfallLayout: WaterfallLayout, heightForItemAtIndex index: Int, itemWidth: CGFloat) -> CGFloat

    /// cell的总列数
    @objc optional func colCountInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> Int
    
    /// cell的列间距
    @objc optional func colMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat
    
    /// cell的行间距
    @objc optional func rowMarginInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> CGFloat
    
    /// collectionView的内容间距
    @objc optional func edgeInsetsInWaterFlowLayout(_ waterfallLayout: WaterfallLayout) -> UIEdgeInsets
}

@objcMembers
class WaterfallLayout: UICollectionViewLayout {
    // MARK: - 默认参数
    /// 默认列数
    static let defaultColCount: Int = 3
    /// 默认cell列间距
    static let defaultColMargin: CGFloat = 10
    /// 默认cell行间距
    static let defaultRowMargin: CGFloat = 10
    /// collectionView的内容间距
    static let defaultEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    // MARK: - 协议参数
    var colCount: Int {
        let colCount = delegate?.colCountInWaterFlowLayout?(self) ?? Self.defaultColCount
        return colCount > 0 ? colCount : 1
    }
    var colMargin: CGFloat {
        delegate?.colMarginInWaterFlowLayout?(self) ?? Self.defaultColMargin
    }
    var rowMargin: CGFloat {
        delegate?.rowMarginInWaterFlowLayout?(self) ?? Self.defaultRowMargin
    }
    var edgeInsets: UIEdgeInsets {
        delegate?.edgeInsetsInWaterFlowLayout?(self) ?? Self.defaultEdgeInsets
    }
    
    // MARK: - 代理
    weak var delegate: (AnyObject & WaterfallLayoutDelegate)? = nil
    
    // MARK: - 布局基础参数
    private var contentSize: CGSize = .zero
    private var attrsArray: [UICollectionViewLayoutAttributes] = []
    private var nowAttrsGrid: AttributesGrid = AttributesGrid()
    private var oldAttrsGrid: AttributesGrid = AttributesGrid()
    
    // MARK: - 布局刷新参数
    private var isReloadSection = false
    private var insertIndexPaths: [IndexPath] = []
    private var deleteIndexPaths: [IndexPath] = []
    private var reloadIndexPaths: [IndexPath] = []
    private var appearingInitialYs: [AttributesSeat: CGFloat] = [:]
    private var disappearingFinalYs: [AttributesSeat: CGFloat] = [:]
    
    // MARK: - 布局异步参数
    private var isAsyncLayout: Bool = false
    private var tempContentSize: CGSize?
    private var tempAttrsArray: [UICollectionViewLayoutAttributes]?
    private var tempAttrsGrid: AttributesGrid?
    
    // MARK: - Override
    
    override func prepare() {
        super.prepare()
        
        defer {
            tempContentSize = nil
            tempAttrsArray = nil
            tempAttrsGrid = nil
        }
        
        if isAsyncLayout,
           let tempContentSize = self.tempContentSize,
           let tempAttrsArray = self.tempAttrsArray,
           let tempAttrsGrid = self.tempAttrsGrid
        {
            attrsArray = tempAttrsArray
            nowAttrsGrid = tempAttrsGrid
            contentSize = tempContentSize
            return
        }
        
        isAsyncLayout = false
        setupAttributes()
        setupContentSize()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attrsArray
    }
    
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        super.layoutAttributesForItem(at: indexPath)
//    }
    
    override var collectionViewContentSize: CGSize {
        contentSize
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        if isAsyncLayout {
            super.prepare(forCollectionViewUpdates: updateItems)
            return
        }
        
        prepareUpdateItems(updateItems)
        prepareColumnDiffYs()
    }

    override func finalizeCollectionViewUpdates() {
        oldAttrsGrid.attrsColumns = nowAttrsGrid.attrsColumns
        
        isReloadSection = false
        insertIndexPaths.removeAll()
        deleteIndexPaths.removeAll()
        reloadIndexPaths.removeAll()
        
        appearingInitialYs.removeAll()
        disappearingFinalYs.removeAll()
        
        isAsyncLayout = false
        tempContentSize = nil
        tempAttrsArray = nil
        tempAttrsGrid = nil
    }
    
    /// 从`刚创建出来时的样式设置`到`正常状态`
    /// 这里设置的是展示动画的【初始状态】，例如如果设置了alpha为0，一开始则为0，接着通过动画变为1
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if isAsyncLayout {
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }
        
        if isReloadSection {
            return reloadSection_initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        } else {
            return updateItems_initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }
    }

    /// 从`正常状态`到`最后消失时的样式设置`
    /// 这里设置的是消失动画的【最终状态】，例如如果设置了alpha为0，通过动画最终变为0
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if isAsyncLayout {
            return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        }
        
        if isReloadSection {
            return reloadSection_finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        } else {
            return updateItems_finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        }
    }
}

extension WaterfallLayout {
    // MARK: - 异步刷新
    func asyncUpdateLayout(itemTotal: Int,
                           heightForItemAtIndex: @escaping (_ index: Int, _ itemWidth: CGFloat) -> CGFloat,
                           completion: (() -> ())?) {
        isAsyncLayout = true
        
        if Thread.isMainThread {
            DispatchQueue.global().async {
                self.asyncUpdateLayout(itemTotal: itemTotal,
                                       heightForItemAtIndex: heightForItemAtIndex,
                                       completion: completion)
            }
            return
        }
        
        var colCount: Int = 0
        var colMargin: CGFloat = 0
        var rowMargin: CGFloat = 0
        var edgeInsets: UIEdgeInsets = .zero
        var collectionViewW: CGFloat = 0
        DispatchQueue.main.sync {
            colCount = self.colCount
            colMargin = self.colMargin
            rowMargin = self.rowMargin
            edgeInsets = self.edgeInsets
            collectionViewW = self.collectionView?.frame.width ?? 0
        }
        
        let itemWidth = (collectionViewW - edgeInsets.left - edgeInsets.right - CGFloat(colCount - 1) * colMargin) / CGFloat(colCount)
        
        var tempContentSize: CGSize = .zero
        var tempAttrsArray: [UICollectionViewLayoutAttributes] = []
        let tempAttrsGrid = AttributesGrid()
        
        let attrsColumns = Array(0 ..< colCount).map { _ in
            AttributesColumn(attributes: [], colHeight: edgeInsets.top)
        }
        
        for item in 0 ..< itemTotal {
            // 找出高度最小的那一列
            var destCol = 0
            var destColumn = attrsColumns[destCol]
            for col in 0..<attrsColumns.count {
                let attrsColumn = attrsColumns[col]
                guard destColumn.colHeight > attrsColumn.colHeight else { continue }
                destColumn = attrsColumn
                destCol = col
            }
            
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
            attrs.frame = CGRect(
                x: edgeInsets.left + CGFloat(destCol) * (itemWidth + colMargin),
                y: destColumn.colHeight + (destColumn.colHeight > edgeInsets.top ? rowMargin : 0),
                width: itemWidth,
                height: heightForItemAtIndex(item, itemWidth)
            )
            destColumn.attributes.append(attrs)
            destColumn.colHeight = attrs.frame.maxY // 刷新最短那列的高度
            
            tempAttrsArray.append(attrs)
        }
        
        tempAttrsGrid.attrsColumns = attrsColumns
        
        var colHeight = attrsColumns[0].colHeight
        for attrsColumn in attrsColumns where colHeight < attrsColumn.colHeight {
            colHeight = attrsColumn.colHeight
        }
        colHeight += edgeInsets.bottom
        tempContentSize = CGSize(width: 0, height: colHeight)
        
        DispatchQueue.main.async {
            self.tempContentSize = tempContentSize
            self.tempAttrsArray = tempAttrsArray
            self.tempAttrsGrid = tempAttrsGrid
            completion?()
        }
    }
}

// MARK: - 私有计算函数

private extension WaterfallLayout {
    func setupAttributes() {
        attrsArray.removeAll()
        nowAttrsGrid.attrsColumns.removeAll()
        
        let colCount = self.colCount
        let colMargin = self.colMargin
        let rowMargin = self.rowMargin
        let edgeInsets = self.edgeInsets
        
        let collectionViewW = collectionView?.frame.width ?? 0
        let itemTotal = collectionView?.numberOfItems(inSection: 0) ?? 0
        let itemWidth = (collectionViewW - edgeInsets.left - edgeInsets.right - CGFloat(colCount - 1) * colMargin) / CGFloat(colCount)
        
        let attrsColumns = Array(0 ..< colCount).map { _ in
            AttributesColumn(attributes: [], colHeight: edgeInsets.top)
        }
        
        for item in 0 ..< itemTotal {
            // 找出高度最小的那一列
            var destCol = 0
            var destColumn = attrsColumns[destCol]
            for col in 0..<attrsColumns.count {
                let attrsColumn = attrsColumns[col]
                guard destColumn.colHeight > attrsColumn.colHeight else { continue }
                destColumn = attrsColumn
                destCol = col
            }
            
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
            attrs.frame = CGRect(
                x: edgeInsets.left + CGFloat(destCol) * (itemWidth + colMargin),
                y: destColumn.colHeight + (destColumn.colHeight > edgeInsets.top ? rowMargin : 0),
                width: itemWidth,
                height: delegate?.waterfallLayout(self, heightForItemAtIndex: item, itemWidth: itemWidth) ?? itemWidth
            )
            destColumn.attributes.append(attrs)
            destColumn.colHeight = attrs.frame.maxY // 刷新最短那列的高度
            
            attrsArray.append(attrs)
        }
        
        nowAttrsGrid.attrsColumns = attrsColumns
    }
    
    func setupContentSize() {
        let attrsColumns = nowAttrsGrid.attrsColumns
        var colHeight = attrsColumns[0].colHeight
        for attrsColumn in attrsColumns where colHeight < attrsColumn.colHeight {
            colHeight = attrsColumn.colHeight
        }
        colHeight += edgeInsets.bottom
        contentSize = CGSize(width: 0, height: colHeight)
    }
}

private extension WaterfallLayout {
    func reloadSection_initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // 当刷新整个Section：
        var attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        if attributes == nil {
            // 如果super获取为空，则说明是新增的item，新增的item默认就直接在最终位置停留，只有透明度的过渡
            // 为了让item能有过渡动画，当super获取为空、并且之前的cell处于正在显示的区域时，则手动创建一个来实现过渡动画
            if let oldAttds = oldAttrsGrid.findAttributes(with: itemIndexPath) {
                // scrollView的bounds就是正在显示的区域
                let showingRect = collectionView?.bounds ?? .zero
                if showingRect.intersects(oldAttds.frame) {
                    attributes = UICollectionViewLayoutAttributes(forCellWith: itemIndexPath)
//                    print("jpjpjp \(itemIndexPath.item) 正在显示区域")
//                } else {
//                    print("jpjpjp \(itemIndexPath.item) 不在显示区域")
                }
            }
//            else {
//                print("jpjpjp \(itemIndexPath.item) 本来就不存在")
//            }
        }
        
        guard let attributes = attributes else { return nil }
        attributes.zIndex = 1
        attributes.alpha = 0
        
        guard let nowSeat = nowAttrsGrid[itemIndexPath] else {
            return attributes
        }
        
        if let oldAttrs = oldAttrsGrid[nowSeat] {
            attributes.frame = oldAttrs.frame
            return attributes
        }
        
        let nowAttrs = nowAttrsGrid[nowSeat]!
        attributes.frame = nowAttrs.frame
        if let initialY = appearingInitialYs[nowSeat] {
            attributes.frame.origin.y = initialY
        }
        
        return attributes
    }
    
    func reloadSection_finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else { return nil }
        attributes.zIndex = 0
        attributes.alpha = 0
        
        guard let oldSeat = oldAttrsGrid[itemIndexPath] else {
            return attributes
        }
        
        if let nowAttrs = nowAttrsGrid[oldSeat]  {
            attributes.frame = nowAttrs.frame
            return attributes
        }
        
        let oldAttrs = oldAttrsGrid[oldSeat]!
        attributes.frame = oldAttrs.frame
        if let finalY = disappearingFinalYs[oldSeat] {
            attributes.frame.origin.y = finalY
        }
        
        return attributes
    }
    
    func updateItems_initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) else { return nil }
        
        if insertIndexPaths.contains(itemIndexPath) {
            attributes.alpha = 0
        } else if deleteIndexPaths.contains(itemIndexPath) {
            attributes.alpha = 1
        } else if reloadIndexPaths.contains(itemIndexPath) {
            attributes.alpha = 1
        }
        // 删除不会走这里，不用判断 deleteIndexPaths
        
        return attributes
    }
    
    func updateItems_finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else { return nil }
        
        if insertIndexPaths.contains(itemIndexPath) {
            attributes.alpha = 1
        } else if deleteIndexPaths.contains(itemIndexPath) {
            attributes.alpha = 0
        } else if reloadIndexPaths.contains(itemIndexPath) {
            // 刷新：旧的是覆盖在新的上面，现在对旧的进行渐变消失
            attributes.alpha = 0
        }
        
        return attributes
    }
}

private extension WaterfallLayout {
    func prepareUpdateItems(_ updateItems: [UICollectionViewUpdateItem]) {
        for updateItem in updateItems {
            switch updateItem.updateAction {
            case .insert:
                insertIndexPaths.append(updateItem.indexPathAfterUpdate!)
                
            case .delete:
                deleteIndexPaths.append(updateItem.indexPathBeforeUpdate!)
                
            case .reload:
                if updateItem.indexPathAfterUpdate!.item < Int.max {
                    // indexPathBeforeUpdate indexPathAfterUpdate 都一样
                    reloadIndexPaths.append(updateItem.indexPathAfterUpdate!)
                } else {
                    // item 为 NSIntegerMax 时就是 reloadSections 更新整个 section 的（NSIndexSet）
                    isReloadSection = true
                    break
                }
                
            default:
                break
            }
        }
    }
    
    func prepareColumnDiffYs() {
        guard isReloadSection, oldAttrsGrid.attrsColumns.count == nowAttrsGrid.attrsColumns.count else {
            return
        }

        let rowMargin = self.rowMargin
        let topInset = self.edgeInsets.top
        func makeColumnDiffYs(_ diffYs: inout [AttributesSeat: CGFloat],
                              col: Int, colHeight: CGFloat,
                              attributes: [UICollectionViewLayoutAttributes],
                              from: Int, to: Int) {
            var itemY = colHeight
            for row in from ..< to {
                let seat = AttributesSeat(col: col, row: row)
                diffYs[seat] = itemY + (itemY > topInset ? rowMargin : 0)
                itemY += attributes[row].frame.height
            }
        }

        let colCount = self.colCount
        let oldAttrsColumns = oldAttrsGrid.attrsColumns
        let nowAttrsColumns = nowAttrsGrid.attrsColumns
        for col in 0 ..< colCount {
            let oldAttrColumn = oldAttrsColumns[col]
            let oldAttributes = oldAttrColumn.attributes
            let oldRowCount = oldAttributes.count

            let nowAttrColumn = nowAttrsColumns[col]
            let nowAttributes = nowAttrColumn.attributes
            let nowRowCount = nowAttributes.count

            guard oldRowCount != nowRowCount else {
                continue
            }
            
            if oldRowCount > nowRowCount {
                makeColumnDiffYs(&disappearingFinalYs,
                                 col: col, colHeight: nowAttrColumn.colHeight,
                                 attributes: oldAttributes,
                                 from: nowRowCount, to: oldRowCount)
            } else {
                makeColumnDiffYs(&appearingInitialYs,
                                 col: col, colHeight: oldAttrColumn.colHeight,
                                 attributes: nowAttributes,
                                 from: oldRowCount, to: nowRowCount)
            }
        }
    }
}

// MARK: - 私有类
private extension WaterfallLayout {
    struct AttributesSeat: Hashable {
        let col: Int
        let row: Int
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(col)
            hasher.combine(row)
        }
        
        static func == (lhs: AttributesSeat, rhs: AttributesSeat) -> Bool {
            lhs.col == rhs.col && lhs.row == rhs.row
        }
    }
    
    class AttributesColumn {
        var attributes: [UICollectionViewLayoutAttributes] = []
        var colHeight: CGFloat = 0
        
        init(attributes: [UICollectionViewLayoutAttributes], colHeight: CGFloat) {
            self.attributes = attributes
            self.colHeight = colHeight
        }
    }
    
    class AttributesGrid {
        var attrsColumns: [AttributesColumn] = []
        
        func findAttributes(with indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
            let item = indexPath.item
            for col in 0 ..< attrsColumns.count {
                let attributes = attrsColumns[col].attributes
                guard let attrs = attributes.first(where: { $0.indexPath.item == item }) else {
                    continue
                }
                return attrs
            }
            return nil
        }
        
        subscript(seat: AttributesSeat) -> UICollectionViewLayoutAttributes? {
            get {
                guard seat.col >= 0, seat.col < attrsColumns.count else {
                    return nil
                }
                let attributes = attrsColumns[seat.col].attributes
                
                guard seat.row >= 0, seat.row < attributes.count else {
                    return nil
                }
                return attributes[seat.row]
            }
        }
        
        subscript(indexPath: IndexPath) -> AttributesSeat? {
            get {
                let item = indexPath.item
                for col in 0 ..< attrsColumns.count {
                    let attributes = attrsColumns[col].attributes
                    guard let row = attributes.firstIndex(where: { $0.indexPath.item == item }) else {
                        continue
                    }
                    return AttributesSeat(col: col, row: row)
                }
                return nil
            }
        }
        
//        func log() {
//            var str = "\n"
//            for col in 0 ..< attrsColumns.count {
//                str += "-------col: \(col)-------\n"
//                let column = attrsColumns[col]
//                for row in 0 ..< column.attributes.count {
//                    let attrs = column.attributes[row]
//                    str += "["
//                    str += "row: \(row), item: \(attrs.indexPath.item), x: \(attrs.frame.origin.x)"
//                    str += "]\n"
//                }
//                str += "\n"
//            }
//            print("jpjpjp \(str)")
//        }
    }
}
