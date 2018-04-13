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
    func endScrolling(to time: Double)
}

class LayerScrollerView: UIView {
    weak var delegate: LayerScrollerDelegate?

    var scrollingProgrammatically: Bool = false

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

    public var currentTimeForLinePosition: Double {
        let xOffset = self.scrollView.contentOffset.x
        let leftInset = self.scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.scrollView.contentSize.width)
        let videoTime = Double(center) * timePerPoint

        guard videoTime >= 0 else {
            return 0.0
        }

        return videoTime
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

    public func handleTracking(for time: Double) {
        guard !self.scrollView.isTracking else {
            return
        }

        // Calculate size per second
        let pointsPerSecond: Double =  Double(self.scrollView.contentSize.width) / self.videoDuration
        // Calculate x scroll value
        let x = time * (pointsPerSecond)
        let y = self.scrollView.contentOffset.y

        // Scroll to time
        let frame = CGRect(x: x, y: Double(y), width: 0.001, height: 0.001)

        self.scrollingProgrammatically = true
        self.scrollView.scrollRectToVisible(frame, animated: false)
        self.scrollingProgrammatically = false
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

        self.handleScroll2(from: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScroll(from: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        self.handleScroll(from: scrollView)
    }

    func handleScroll(from scrollView: UIScrollView) {
        guard !self.scrollingProgrammatically else {
            return
        }

        let videoTime = self.currentTimeForLinePosition

        guard videoTime <= videoDuration else {
            delegate?.endScrolling(to: videoDuration)
            return
        }
        delegate?.endScrolling(to: videoTime)
    }

    func handleScroll2(from scrollView: UIScrollView) {
        guard !self.scrollingProgrammatically else {
            return
        }

        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.scrollView.contentSize.width)
        let videoTime = Double(center) * timePerPoint

        guard videoTime >= 0 else {
            delegate?.isScrolling(to: 0.0)
            return
        }
        guard videoTime <= videoDuration else {
            delegate?.isScrolling(to: videoDuration)
            return
        }
        delegate?.isScrolling(to: videoTime)
    }
}

class FrameLayerView: UIView {
    required init(framerate: Double, videoDuration: Double, videoFrameWidth: CGFloat, videoFrameHeight: CGFloat) {
        super.init(frame: .zero)

        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let video = VideoAsset(assetName: "vert", url: videoURL)

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

