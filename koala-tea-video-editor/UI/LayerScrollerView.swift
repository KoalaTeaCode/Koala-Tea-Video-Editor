//
//  scroller.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/6/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

protocol LayerScrollerDelegate: class {
    func isScrolling(to time: Double)
    func endScrolling(at time: Double)
}

class LayerScrollerView: UIView {
    weak var delegate: LayerScrollerDelegate?

    let scrollView = UIScrollView()
    let layerContainerView = LayerContainerView()

    let framerate: Double
    let videoDuration: Double

    private var layerHeight: CGFloat = 50.0

    private var videoFrameWidth: CGFloat {
        return 50 * (16/9)
    }
    private var widthFromVideoDuration: CGFloat {
        let totalVideoFrames = videoDuration * framerate
        let frameCountForView = totalVideoFrames * 0.1
        // Frame count for view * width wanted for each frame
        let totalWidth = CGFloat(frameCountForView) * videoFrameWidth
        return totalWidth
    }

    required init(frame: CGRect, framerate: Double, videoDuration: Double) {
        self.framerate = framerate
        self.videoDuration = videoDuration

        super.init(frame: frame)

        self.setupViews()

        // Playback current time line
        let centerLineView = UIView(frame: CGRect(x: self.center.x, y: 0, width: 2, height: self.height))
        centerLineView.backgroundColor = .white
        centerLineView.isUserInteractionEnabled = false
        self.addSubview(centerLineView)

        // Video frame view
        let view = FrameLayerView(framerate: framerate,
                                  videoDuration: videoDuration,
                                  videoFrameWidth: self.videoFrameWidth,
                                  videoFrameHeight: self.layerHeight)
        self.layerContainerView.addSubview(view)

        self.scrollView.contentSize = self.layerContainerView.size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func addLayerView(with layer: EditableLayer) {
        let frame = CGRect(x: 0, y: 0, width: self.widthFromVideoDuration, height: 30.0)
        let layerView = LayerSliderView(frame: frame, editableLayer: layer, assetDuration: self.videoDuration)
        
        self.layerContainerView.addSubview(layerView)

        self.scrollView.contentSize = self.layerContainerView.size
    }

    private func setupViews() {
        self.setupScrollView()

        // Setup stack view
        self.layerContainerView.frame = .zero
        self.scrollView.addSubview(self.layerContainerView)
    }

    private func setupScrollView() {
        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.scrollView.delegate = self

        self.scrollView.contentSize = CGSize(width: self.scrollView.width, height: self.scrollView.height)
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: scrollView.width/2, bottom: 0, right: scrollView.width/2)

        self.addSubview(scrollView)

        self.scrollView.contentOffset = CGPoint(x: -(scrollView.width/2) , y: 0)
        self.scrollView.decelerationRate = 0.5

        self.scrollView.showsHorizontalScrollIndicator = true
        self.scrollView.showsVerticalScrollIndicator = false
    }
}

extension LayerScrollerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.handleScroll(from: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScroll(from: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        self.handleScroll(from: scrollView)
    }

    func handleScroll(from scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.scrollView.contentSize.width)
        let videoTime = Double(center) * timePerPoint

        guard videoTime >= 0 else {
            delegate?.endScrolling(at: 0.0)
            return
        }
        guard videoTime <= videoDuration else {
            delegate?.endScrolling(at: videoDuration)
            return
        }
        delegate?.endScrolling(at: videoTime)
    }
}

class FrameLayerView: UIView {
    required init(framerate: Double, videoDuration: Double, videoFrameWidth: CGFloat, videoFrameHeight: CGFloat) {
        super.init(frame: .zero)

        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let video = VideoAsset(assetName: "vert", url: videoURL, frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CanvasFrameSizes._9x16(forSize: CGSize(width: 720, height: 720)).rawValue))

        guard let images = video.urlAsset.getAllFramesAsUIImages() else {
            assertionFailure("dont get here")
            return
        }

        let totalVideoFrames = videoDuration * framerate
        let frameCountForView = totalVideoFrames * 0.1
        // Frame count for view * width wanted for each frame
        let totalWidth = CGFloat(frameCountForView) * videoFrameWidth
        let divisor = (Double(images.count) / frameCountForView).rounded()

        //---- Get images
        var imageViews = [UIImageView]()
        // Get an even spread of images per the frame count
        var counter: CGFloat = 0
        for image in images {
            guard counter.truncatingRemainder(dividingBy: CGFloat(divisor)) == 0 else {
                counter += 1
                continue
            }

            let x: CGFloat = CGFloat(imageViews.count) * videoFrameWidth

            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: videoFrameWidth, height: videoFrameHeight))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true

            imageViews.append(imageView)
            counter += 1
        }
        //----

        self.width = totalWidth
        self.height = videoFrameHeight
        self.clipsToBounds = true
        self.addSubviews(imageViews)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

