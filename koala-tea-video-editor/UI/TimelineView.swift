//
//  TimelineView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

protocol TimelineViewDelegate: class {
    func isScrolling(to time: Double)
    func endScrolling(at time: Double)
}

class TimelineView: UIView {
    weak var delegate: TimelineViewDelegate?

    private var layerScrollerView: LayerScrollerView!

    public var currentTimeForLinePosition: Double {
        return self.layerScrollerView.currentTimeForLinePosition
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // @TODO: Add framerate and duration here
    func setupTimeline() {
        // Layer Scroller View
        let frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
        layerScrollerView = LayerScrollerView(frame: frame, framerate: 24, videoDuration: 9.77)
        layerScrollerView.backgroundColor = .darkGray
        layerScrollerView.delegate = self
        self.addSubview(layerScrollerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func addLayerView(with layer: EditableLayer) {
        self.layerScrollerView.addLayerView(with: layer)
    }

    public func handleTracking(for time: Double) {
        self.layerScrollerView.handleTracking(for: time)
    }
}

extension TimelineView: LayerScrollerDelegate {
    func isScrolling(to time: Double) {
        delegate?.isScrolling(to: time)
    }

    func endScrolling(to time: Double) {
        delegate?.endScrolling(at: time)
    }
}
