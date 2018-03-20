//
//  ViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import AVFoundation
import KoalaTeaPlayer

class LayerContainerViewOLD: UIScrollView {
    let layerViews: [LayerSliderView]

    let stackView: UIStackView = UIStackView()

    required init(frame: CGRect, layerViews: [LayerSliderView]) {
        self.layerViews = layerViews

        super.init(frame: frame)

        self.backgroundColor = UIColor(red: 0.152941176470588, green: 0.149019607843137, blue: 0.152941176470588, alpha: 1.0)

        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        stackView.width = self.width
        self.addSubview(self.stackView)

        self.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: stackView.rightAnchor).isActive = true

        self.contentInset = UIEdgeInsets(top: 16, left: 150, bottom: 0, right: 0)
        self.setContentOffset(CGPoint(x: 0, y: -self.contentInset.top), animated: false)

//        for view in layerViews {
//            self.addSubviewToStackView(view)
//        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func handlePlaying(at time: Double) {
        for layer in layerViews {
            layer.editableLayer.handlePlaying(at: time)
        }
    }

    /// Use this instead of just adding a subview
    func addSubviewToStackView(_ view: UIView) {
        // Index 0 is for the video player
        self.stackView.addArrangedSubview(view)

//        self.setContentOffset(CGPoint(x: 0, y: -self.contentInset.top), animated: true)
        for (subview) in self.stackView.subviews {
            subview.width = self.width
            stackView.height = subview.height * CGFloat(self.stackView.subviews.count)
        }
    }
}

class EditableLayer: DraggableView {
    var startTime: Double = 0
    var endTime: Double = 0

    var animations: [CABasicAnimation] = []
    var visible: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStartTime(to time: Double) {
        self.startTime = time

        // Create show animation
        let animation = CABasicAnimation.showLayerAnimation(at: startTime)

        // Add animation to [animations] to be used on export
        self.animations.append(animation)
    }

    func setEndTime(to time: Double) {
        self.endTime = time

        // Create hide animation
        let animation = CABasicAnimation.hideLayerAnimation(at: endTime)

        // Add animation to [animations] to be used on export
        self.animations.append(animation)
    }

    /// Function to handle animations in the layer by the time of a video
    func handlePlaying(at time: Double) {
        guard time >= startTime && time <= endTime else {
            hideView()
            return
        }

        showView()
    }

    private func showView() {
        guard !self.visible else {
            return
        }
        self.visible = true

        let animation = CABasicAnimation.showLayerAnimation()

        self.layer.add(animation, forKey: "show")
    }

    private func hideView() {
        guard self.visible else {
            return
        }
        self.visible = false

        let animation = CABasicAnimation.hideLayerAnimation()

        self.layer.add(animation, forKey: "hide")
    }
}

class ViewController: UIViewController {
    var editorController: VideoEditorController

    required init(videos: [VideoAsset]) {
        self.editorController = VideoEditorController(videos: videos)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let vid1 = VideoAsset(assetName: "", url: videoURL, frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CanvasFrameSizes._9x16(forSize: CGSize(width: 1280, height: 720)).rawValue))

        super.viewDidLoad()

        editorController.setupCanvasView(in: self.view, with: .zero)
        editorController.setupTimelineView(in: self.view, with: .zero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// @TODO: Move this to canvas view
extension ViewController: AssetPlayerDelegate {
    func currentAssetDidChange(_ player: AssetPlayer) {

    }

    func playerIsSetup(_ player: AssetPlayer) {
        guard player.duration != 0 && !player.duration.isNaN else {
            return
        }

    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {

    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {

    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {

    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {

    }
}

//extension ViewController: TimelineViewDelegate {
//    func isScrolling(to time: Double) {
//        self.assetPlayer?.pause()
//        self.assetPlayer?.seekTo(interval: time)
//    }
//
//    func endScrolling(at time: Double) {
//        // Set new start time
//        self.assetPlayer?.startTimeForLoop = time
//        self.assetPlayer?.seekTo(interval: time)
//        self.assetPlayer?.play()
//    }
//
//    func addLayerPressed() {
//        // @TODO: Get current time from timeline
//        self.layerManager.addLayer(atTime: 1.0)
//    }
//}
//
//extension ViewController: EditableLayerManagerDelegate {
//    func didAddLayer(_ layer: EditableLayer) {
//        // Add layer to canvas
//        self.canvasView.addSubview(layer)
//
//        // Add layer to timeline
//        self.timelineView.addLayerView(with: layer)
//    }
//}

// MARK: VideoEditorController

class VideoEditorController: NSObject {
    var videos: [VideoAsset]

    let canvasView = UIView()
    let controlsView = UIView()
    let timelineView = TimelineView()
    let layerManager = EditableLayerManager()

    init(videos: [VideoAsset]) {
        self.videos = videos

        super.init()

        layerManager.delegate = self
        timelineView.delegate = self
//        controlsView.delegate = self
    }

    func setupCanvasView(in view: UIView, with frame: CGRect) {
        self.canvasView.frame = frame
        view.addSubview(self.canvasView)
    }

    func setupTimelineView(in view: UIView, with frame: CGRect) {
        self.timelineView.frame = frame
        view.addSubview(self.timelineView)

        self.timelineView.setupTimeline()
    }

    func setupControlsView(in: UIView, with frame: CGRect) {
        // Controls view
//        controlsView.frame = CGRect(origin: .zero, size: CGSize(width: self.width, height: 40.0))
//        self.addSubview(controlsView)

//        let button = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: controlsView.height * 3, height: controlsView.height)))
//        button.setTitle("Add Layer", for: .normal)
//        button.addTarget(self, action: #selector(self.buttonTouched), for: .touchUpInside)
//        self.controlsView.addSubview(button)
    }

    // @TODO: move this to controls view delegate
    func addLayerPressed() {
        // @TODO: Get current time from timeline
        self.layerManager.addLayer(atTime: 1.0)
    }
}

extension VideoEditorController: TimelineViewDelegate {
    func isScrolling(to time: Double) {
//        self.assetPlayer?.pause()
//        self.assetPlayer?.seekTo(interval: time)
    }

    func endScrolling(at time: Double) {
//        // Set new start time
//        self.assetPlayer?.startTimeForLoop = time
//        self.assetPlayer?.seekTo(interval: time)
//        self.assetPlayer?.play()
    }
}

extension VideoEditorController: EditableLayerManagerDelegate {
    func didAddLayer(_ layer: EditableLayer) {
        // Add layer to canvas
        self.canvasView.addSubview(layer)

        // Add layer to timeline
        self.timelineView.addLayerView(with: layer)
    }
}

// MARK: Editable Layer Manager

protocol EditableLayerManagerDelegate: NSObjectProtocol {
    func didAddLayer(_ layer: EditableLayer)
}

class EditableLayerManager: NSObject {
    weak var delegate: EditableLayerManagerDelegate?

    var layers = [EditableLayer]()

    override init() {
        super.init()

    }

    func addLayer(atTime startTime: Double) {
        let layer = EditableLayer()
        layer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        layer.backgroundColor = UIColor.random
        layer.setStartTime(to: startTime)
        layer.setEndTime(to: startTime + 1)

        self.layers.append(layer)

        delegate?.didAddLayer(layer)
    }
}
