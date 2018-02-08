//
//  FramesScrollerView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/17/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

protocol FramesScrollerViewDelegate: class {
    func isScrolling(to time: Double)
    func endScrolling(at time: Double)
}

class FramesScrollerView: UIView {
    weak var delegate: FramesScrollerViewDelegate?

    let scrollView = UIScrollView()

    let framerate: Double
    let videoDuration: Double

    let images: [UIImage]
    var imageContainerView = UIView()

    var videoFrameWidth: CGFloat {
        guard let firstImage = self.images.first else {
            assertionFailure("No first image")
            return 0.0
        }
        let frameWidth: CGFloat = firstImage.size.width / 8
        return frameWidth
    }

    var videoFrameHeight: CGFloat {
        guard let firstImage = self.images.first else {
            assertionFailure("No first image")
            return 0.0
        }
        let frameHeight: CGFloat = firstImage.size.height / 8
        return frameHeight
    }

    var frameCount: Double {
        return Double(imageContainerView.subviews.count)
    }

    init(frame: CGRect, images: [UIImage], framerate: Double, videoDuration: Double) {
        self.images = images
        self.framerate = framerate
        self.videoDuration = videoDuration

        super.init(frame: frame)

        self.setupViews()

        let centerLineView = UIView(frame: CGRect(x: self.center.x, y: 0, width: 2, height: self.height))
        centerLineView.backgroundColor = .red
        self.addSubview(centerLineView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.setupImageContainerView()
        self.setupScrollView()
    }

    private func setupScrollView() {
        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.scrollView.delegate = self

        self.scrollView.contentSize = CGSize(width: self.imageContainerView.width, height: videoFrameHeight)
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: scrollView.width/2, bottom: 0, right: scrollView.width/2)

        self.addSubview(scrollView)

        scrollView.contentOffset = CGPoint(x: -(scrollView.width/2), y: 0)
        scrollView.decelerationRate = 0.5
    }

    private func setupImageContainerView() {
        var imageViews = [UIImageView]()

        // duration / timePerFrame * 20%
        // This is how many total frames we want to have
        let timePerFrame = (1.0/framerate)
        let endFrameCount = (videoDuration/timePerFrame) * 0.1
        let divisor = (Double(images.count) / endFrameCount).rounded()

        var counter: CGFloat = 0
        for image in images {
            guard counter.truncatingRemainder(dividingBy: CGFloat(divisor)) == 0 else {
                counter += 1
                continue
            }

            var x: CGFloat = 0
            if image != images.first {
                x = imageViews.last!.frame.maxX
            }
            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: videoFrameWidth, height: videoFrameHeight))
            imageView.image = image

            imageViews.append(imageView)
            counter += 1
        }

        let frameDifference = Double(imageViews.count) - endFrameCount
        let frameDifferenceWidth = Double(videoFrameWidth) * frameDifference
        let totalWidthOfAllImagesViews = (videoFrameWidth * CGFloat(imageViews.count))
        let containerWidth = totalWidthOfAllImagesViews - CGFloat(frameDifferenceWidth)

        imageContainerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: videoFrameHeight))
        imageContainerView.clipsToBounds = true
        imageContainerView.addSubviews(imageViews)
        self.scrollView.addSubview(imageContainerView)
    }
}

extension FramesScrollerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.imageContainerView.width)
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

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.imageContainerView.width)
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

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        
        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.videoDuration / Double(self.imageContainerView.width)
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

