//
//  EditableLayerSlider.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/18/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

class EditableLayerSlider: RangeSeekSlider {
    var duration: Double = 0 {
        didSet {
            self.maxValue = CGFloat(duration)
        }
    }

    var editableLayer: EditableLayer = EditableLayer() {
        didSet {
            self.selectedMinValue = CGFloat(editableLayer.startTime)
            self.selectedMaxValue = CGFloat(editableLayer.endTime)
        }
    }

    required init(frame: CGRect) {
        super.init(frame: frame)
        self.colorBetweenHandles = .cyan
        self.tintColor = UIColor(red: 0.12156862745098, green: 0.117647058823529, blue: 0.12156862745098, alpha: 1.0)
        self.lineHeight = 24
        self.minDistance = 0.1
        self.minLabelColor = .black
        self.maxLabelColor = .black

        self.minValue = 0

        self.leftHandleImage = #imageLiteral(resourceName: "indicator-left")
        self.rightHandleImage = #imageLiteral(resourceName: "indicator-right")

        self.layer.cornerRadius = 0

        self.height = self.fullHeight
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
