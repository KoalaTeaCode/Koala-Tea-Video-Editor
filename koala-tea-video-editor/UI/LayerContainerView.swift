//
//  LayerContainerView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

class LayerContainerView: UIView {
    let spacing: CGFloat = 10.0

    override func layoutSubviews() {
        super.layoutSubviews()

        self.calculateSize()
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)

        let subviewCount = self.subviews.count - 1
        view.frame.origin = CGPoint(x: 0.0, y: ((view.height + spacing) * CGFloat(subviewCount)) + spacing)

        self.calculateSize()
    }

    private func calculateSize() {
        // Calculate content size
        var contentRect = CGRect.zero
        for view in self.subviews {
            contentRect = contentRect.union(view.frame)
        }

        self.frame.size = contentRect.size
    }
}
