//
//  LayerSliderView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/19/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

/// Container view for slider that manages an EditableLayer
class LayerSliderView: UIView {

    var editableLayer: EditableLayer
    let rangeSlider = EditableLayerSlider(frame: .zero)

    init(frame: CGRect, editableLayer: EditableLayer, assetDuration: Double) {
        self.editableLayer = editableLayer
        super.init(frame: frame)

        rangeSlider.width = self.width
        rangeSlider.lineHeight = frame.height

        rangeSlider.duration = assetDuration
        rangeSlider.editableLayer = editableLayer
        rangeSlider.delegate = self

        rangeSlider.selectedMinValue = 0
        rangeSlider.selectedMaxValue = 1

        self.addSubview(rangeSlider)

        self.height = rangeSlider.fullHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        rangeSlider.width = self.width
    }
}

extension LayerSliderView: RangeSeekSliderDelegate {
    func didStartTouches(in slider: RangeSeekSlider) {
        // Slider started tracking so bring self to front of superview so labels do not get cut off
        self.superview?.bringSubview(toFront: self)
    }

    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {
        let startTime = (minValue * 10.0).rounded() / 10.0
        let endTime = (maxValue * 10.0).rounded() / 10.0

        self.editableLayer.startTime = Double(startTime)
        self.editableLayer.endTime = Double(endTime)
    }
}
