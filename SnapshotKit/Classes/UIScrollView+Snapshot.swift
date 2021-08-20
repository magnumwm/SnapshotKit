//
//  UIScrollView+Snapshot.swift
//  SnapshotKit
//
//  Created by York on 2018/9/9.
//

import UIKit

extension UIScrollView {

    override
    public func takeSnapshotOfVisibleContent() -> UIImage? {
        // 获取当前可视区域的rect
        var visibleRect = self.bounds
        visibleRect.origin = self.contentOffset

        return self.takeSnapshotOfFullContent(for: visibleRect)
    }

    override
    public func takeSnapshotOfFullContent() -> UIImage? {
        let originalFrame = self.frame
        let originalOffset = self.contentOffset

        self.frame = CGRect.init(origin: originalFrame.origin, size: self.contentSize)
        self.contentOffset = .zero

        let backgroundColor = self.backgroundColor ?? UIColor.white

        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(backgroundColor.cgColor)

        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.frame = originalFrame
        self.contentOffset = originalOffset

        return image
    }

    override
    public func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((UIImage?) -> Void)) {
        // 分页绘制内容到ImageContext
        let originalOffset = self.contentOffset

        // 当contentSize.height<bounds.height时，保证至少有1页的内容绘制
        var pageNum = 1
        if self.contentSize.height > self.bounds.height {
            pageNum = Int(floorf(Float(self.contentSize.height / self.bounds.height)))
        }

        let backgroundColor = self.backgroundColor ?? UIColor.white

        UIGraphicsBeginImageContextWithOptions(self.contentSize, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            completion(nil)
            return
        }
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(backgroundColor.cgColor)

        self.drawScreenshotOfPageContent(0, maxIndex: pageNum) {
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.contentOffset = originalOffset
            completion(image)
        }
    }

    fileprivate func drawScreenshotOfPageContent(_ index: Int, maxIndex: Int, completion: @escaping () -> Void) {

        self.setContentOffset(CGPoint(x: 0, y: CGFloat(index) * self.frame.size.height), animated: false)
        let pageFrame = CGRect(x: 0, y: CGFloat(index) * self.frame.size.height, width: self.bounds.size.width, height: self.bounds.size.height)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.drawHierarchy(in: pageFrame, afterScreenUpdates: true)

            if index < maxIndex {
                self.drawScreenshotOfPageContent(index + 1, maxIndex: maxIndex, completion: completion)
            }else{
                completion()
            }
        }
    }

    override
    public func asyncTakeSnapshotOfPartialContent(_ contentRect:CGRect,
                                                  composition: ((CGContext) -> CGFloat)? = nil,
                                                  _ completion: @escaping ((UIImage?) -> Void)) {
        // 分页绘制内容到ImageContext
        let originalOffset = self.contentOffset

        // 当contentSize.height<bounds.height时，保证至少有1页的内容绘制
        var pageNum = 1
        if contentRect.size.height > self.bounds.height {
            pageNum = Int(floorf(Float(contentRect.size.height / self.bounds.height)))
        }

        let backgroundColor = self.backgroundColor ?? UIColor.white

        UIGraphicsBeginImageContextWithOptions(contentRect.size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            completion(nil)
            return
        }
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(backgroundColor.cgColor)

        var offset:CGFloat = 0
        if let composition = composition {
            offset = composition(context)
        }

        self.drawScreenshotOfPagePartialContent(0, maxIndex: pageNum, offset: offset, contentHeight: contentRect.height) {
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.contentOffset = originalOffset
            completion(image)
        }
    }

    fileprivate func drawScreenshotOfPagePartialContent(_ index: Int, maxIndex: Int, offset: CGFloat, contentHeight: CGFloat, completion: @escaping () -> Void) {

        let y = CGFloat(index) * self.frame.size.height
        self.setContentOffset(CGPoint(x: 0, y: y), animated: false)

        let pageFrame = CGRect(x: 0, y: (y+offset), width: self.bounds.size.width, height: self.bounds.size.height)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.drawHierarchy(in: pageFrame, afterScreenUpdates: true)

            if index < maxIndex {
                self.drawScreenshotOfPagePartialContent(index + 1, maxIndex: maxIndex, offset: offset, contentHeight: contentHeight, completion: completion)
            }else{
                completion()
            }
        }
    }
}
