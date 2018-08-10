//
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import AVFoundation

protocol WaveformScrollViewDelegate: class {
    func isScrolling(to time: Double)
    func endScrolling(to time: Double)
}

class WaveformScrollView: UIView {
    weak var delegate: WaveformScrollViewDelegate?

    var samples: [Float]?

    let scrollView: UIScrollView

    private var scrollingProgrammatically: Bool = false
    private var duration: Double = 0.0

    private var pointsPerSecond: Double {
        return self.scrollView.contentSize.width.double / self.duration
    }

    private lazy var selectedOverlayView: UIView = {
        let view = UIView()
        view.height = self.height
        view.backgroundColor = .yellow
        view.alpha = 0.3
        view.isUserInteractionEnabled = false
        self.scrollView.addSubview(view)
        return view
    }()

    private lazy var startTimeIndicatorView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: self.height))
        view.isHidden = true
        view.backgroundColor = .white
        self.scrollView.addSubview(view)
        return view
    }()

    private lazy var endTimeIndicatorView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: self.height))
        view.isHidden = true
        view.backgroundColor = .white
        self.scrollView.addSubview(view)
        return view
    }()

    public var startTime: Double = 0.0 {
        didSet {
            if startTime < 0 {
                startTime = 0
            }

            self.setStartIndicatorView(to: self.startTime)
            
            UIView.animate(withDuration: 0.25) {
                self.selectedOverlayView.x = self.startTime.cgFloat * self.pointsPerSecond.cgFloat
                self.selectedOverlayView.width = self.selectedViewWidth
                self.layoutIfNeeded()
            }
        }
    }
    
    public var endTime: Double = 0.0 {
        didSet {
            if endTime > self.duration {
                endTime = self.duration
            }

            self.setEndIndicatorView(to: self.endTime)

            UIView.animate(withDuration: 0.25) {
                self.selectedOverlayView.width = self.selectedViewWidth
                self.layoutIfNeeded()
            }
        }
    }

    /// Current width of selectedOverlayView
    private var selectedViewWidth: CGFloat {
        if startTime > endTime || endTime < startTime {
            return 0
        }
        return CGFloat((self.endTime - self.startTime) * pointsPerSecond)
    }

    public var currentTimeForLinePosition: Double {
        let xOffset = self.scrollView.contentOffset.x
        let leftInset = self.scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.duration / Double(self.scrollView.contentSize.width)
        let videoTime = Double(center) * timePerPoint

        guard videoTime >= 0 else {
            return 0.0
        }

        return videoTime
    }

    private let currentTimeLabel = UILabel()

    required init(frame: CGRect, videoURL: URL, samples: [Float]?) {
        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        self.samples = samples
        super.init(frame: frame)

        // Setup waveformView
        self.setupWaveformScrollView(with: videoURL)

        // Playback current time line
        let centerLineView = UIView(frame: CGRect(x: self.center.x, y: 0, width: 2, height: self.height))
        centerLineView.backgroundColor = .white
        centerLineView.isUserInteractionEnabled = false
        self.addSubview(centerLineView)

        currentTimeLabel.frame = CGRect(x: centerLineView.frame.maxX + 4, y: centerLineView.frame.maxY - 20, width: 75, height: 20)
        currentTimeLabel.text = "0.0"
        currentTimeLabel.textColor = .white
        currentTimeLabel.isUserInteractionEnabled = false
        self.addSubview(currentTimeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupWaveformScrollView(with fileURL: URL) {
        let audioAsset = AVURLAsset(url: fileURL)
        let audioDuration = audioAsset.duration.seconds
        self.duration = audioDuration

        if self.samples == nil {
            // Greater samples per second for accuracy
            let samplesPerSecond = 1000.0
            let sampleCount = samplesPerSecond * audioDuration
            let samples = AudioProcessor.waveformSamples(from: audioAsset, count: Int(sampleCount))
            self.samples = samples
        }

        let singleWaveWidth = 2.0
        let spacing = singleWaveWidth * 0.75

        // Using audioDuration * 24 or 24 waveforms per second as a baseline for showing this type of waveView
//        let totalWidth = (singleWaveWidth + spacing) * (audioDuration * 24)

        // @TODO: multiplier smaller for larger audio files
        var multiplier = 130.0
        multiplier = 2.0

        // 130p per second
        let totalWidth = multiplier * audioDuration

        let waveView = WaveformGenerator.generateFullWaveform(samples: self.samples!, totalWidth: totalWidth.cgFloat, height: 300, singleWaveWidth: singleWaveWidth.cgFloat, spacing: spacing.cgFloat)

        scrollView.contentInset = UIEdgeInsets(top: 0, left: scrollView.width/2, bottom: 0, right: scrollView.width/2)
        scrollView.contentOffset = CGPoint(x: -(scrollView.width/2) , y: 0)
        scrollView.addSubview(waveView)
        scrollView.contentSize = waveView.size

        scrollView.delegate = self

        self.addSubview(scrollView)

//        // Ticks
//
//        // @TODO: Make this accept any number of ticks other than 1
//        let widthPerSecond = totalWidth.cgFloat / duration.cgFloat
////        let numberOfTicksPerSecond: CGFloat = 4
//        let numberOfTicksPerSecond: CGFloat = 1
//
//        let tickWidthWithSpacing = (widthPerSecond / numberOfTicksPerSecond)
//        let numberOfTotalTicks: CGFloat = (totalWidth.cgFloat / tickWidthWithSpacing).rounded()
//
//        let tickWidth: CGFloat = 2
//
//        // @TODO: Fix last tick being at the end of the duration
//        var counter = 0.0
//        for i in 0...(numberOfTotalTicks).int {
//            var height: CGFloat = 5
//
//            let x: CGFloat = i.cgFloat * tickWidthWithSpacing
//
//            if i.double.truncatingRemainder(dividingBy: numberOfTicksPerSecond.double) == 0 {
//                // Longer height
//                height = 20
//
//                // Add time code
//                let label = UILabel(frame: CGRect(x: x + tickWidth + 8, y: 10, width: 50, height: 10))
//                label.font = UIFont.systemFont(ofSize: 12)
//                // @TODO: would have to round duration to get 1.0
//                let time = self.duration / ((numberOfTotalTicks) / 4).double
//
//                let finTime = (counter * 1.0)
//
//                label.text = String(self.round(finTime, toNearest: 0.01))
//                label.textColor = .white
//                scrollView.addSubview(label)
//
//                counter += 1
//            }
//
//            let view = UIView(frame: CGRect(x: x, y: 0, width: tickWidth, height: height))
//            view.backgroundColor = .lightGray
//            scrollView.addSubview(view)
//        }
    }

    func round(_ value: Double, toNearest: Double) -> Double {
        return Darwin.round(value / toNearest) * toNearest
    }

    public func handleTracking(for time: Double) {
        guard !self.scrollView.isTracking else {
            return
        }

        // Calculate size per second
        let pointsPerSecond: Double = Double(self.scrollView.contentSize.width) / self.duration
        // Calculate x scroll value
        let x = time * (pointsPerSecond)
        let y = self.scrollView.contentOffset.y

        // Scroll to time
        let frame = CGRect(x: x, y: Double(y), width: 0.001, height: 0.001)

        self.scrollingProgrammatically = true
        self.scrollView.scrollRectToVisible(frame, animated: false)
        self.scrollingProgrammatically = false
    }

    public func clearTimes() {
        // Set times to 0
        self.startTime = 0
        self.endTime = 0

        // Hide indicator views
        self.startTimeIndicatorView.isHidden = true
        self.endTimeIndicatorView.isHidden = true
    }

    private func setStartIndicatorView(to time: Double) {
        self.startTimeIndicatorView.isHidden = false

        UIView.animate(withDuration: 0.25) {
            self.startTimeIndicatorView.x = (time.cgFloat * self.pointsPerSecond.cgFloat) - self.startTimeIndicatorView.width
            self.layoutIfNeeded()
        }
    }

    private func setEndIndicatorView(to time: Double) {
        self.endTimeIndicatorView.isHidden = false

        UIView.animate(withDuration: 0.25) {
            self.endTimeIndicatorView.x = time.cgFloat * self.pointsPerSecond.cgFloat
            self.layoutIfNeeded()
        }
    }
}

extension WaveformScrollView: UIScrollViewDelegate {
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let videoTime = self.currentTimeForLinePosition

        if videoTime >= self.duration {
            self.currentTimeLabel.text = createTimeString(time: self.duration.float)
        } else {
            self.currentTimeLabel.text = createTimeString(time: videoTime.float)
        }
        
        self.handleScroll2(from: scrollView)
    }

    func createTimeString(time: Float) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))

        return formatter.string(from: components as DateComponents)!
    }

    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScroll(from: scrollView)
    }

    internal func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        self.handleScroll(from: scrollView)
    }

    fileprivate func handleScroll(from scrollView: UIScrollView) {
        guard !self.scrollingProgrammatically else {
            return
        }

        let videoTime = self.currentTimeForLinePosition

        guard videoTime <= duration else {
            delegate?.endScrolling(to: duration)
            return
        }
        delegate?.endScrolling(to: videoTime)
    }

    fileprivate func handleScroll2(from scrollView: UIScrollView) {
        guard !self.scrollingProgrammatically else {
            return
        }

        let xOffset = scrollView.contentOffset.x
        let leftInset = scrollView.contentInset.left
        let center = xOffset + leftInset

        let timePerPoint: Double = self.duration / Double(self.scrollView.contentSize.width)
        let videoTime = Double(center) * timePerPoint

        guard videoTime >= 0 else {
            delegate?.isScrolling(to: 0.0)
            return
        }
        guard videoTime <= duration else {
            delegate?.isScrolling(to: duration)
            return
        }
        delegate?.isScrolling(to: videoTime)
    }
}
