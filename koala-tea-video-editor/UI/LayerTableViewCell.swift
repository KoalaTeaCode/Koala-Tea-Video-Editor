//
//  LayerTableViewCell.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/17/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

class LayerTableViewCell: UITableViewCell {

    var duration: Double = 0 {
        didSet {
            rangeSlider.maxValue = CGFloat(duration)
        }
    }

    var editableLayer: EditableLayer = EditableLayer() {
        didSet {
            rangeSlider.selectedMinValue = CGFloat(editableLayer.startTime)
            rangeSlider.selectedMaxValue = CGFloat(editableLayer.endTime)
        }
    }

    var rangeSlider = RangeSeekSlider(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        rangeSlider.handleColor = .red
        rangeSlider.colorBetweenHandles = UIColor.random
        rangeSlider.tintColor = .lightGray
        rangeSlider.lineHeight = 15
        rangeSlider.minDistance = 0.1
        rangeSlider.minLabelColor = .black
        rangeSlider.maxLabelColor = .black

        rangeSlider.minValue = 0
        
        self.rangeSlider.leftHandleImage = #imageLiteral(resourceName: "indicator-left")
        self.rangeSlider.rightHandleImage = #imageLiteral(resourceName: "indicator-right")

        rangeSlider.layer.cornerRadius = 0

        self.contentView.addSubview(rangeSlider)

        rangeSlider.frame = CGRect(x: 0, y: 0, width: 375, height: rangeSlider.fullHeight)

        self.contentView.heightAnchor.constraint(equalToConstant: rangeSlider.height).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
