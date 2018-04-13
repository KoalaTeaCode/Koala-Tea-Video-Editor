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

// VC
import AVKit
import MobileCoreServices
import Photos

class EditableLayer: DraggableView {
    var startTime: Double = 0
    var endTime: Double = 0

    var animations: [CABasicAnimation] = []
    var visible: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didtap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapGesture)
    }

    // @TODO: Replace alert with handling text
    @objc func didtap(_ gesture: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Add Text", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "Done", style: .default) { (action) in
            guard let textfield = alert.textFields?.first else {
                return
            }

            self.text = textfield.text
        }
        alert.addAction(action)

        alert.addTextField { (textfield) in }

        superview!.parentViewController!.present(alert, animated: true, completion: nil)
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
    override func viewDidLoad() {
        super.viewDidLoad()

        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let vid1 = VideoAsset(assetName: "", url: videoURL)

        let vc = EditorViewController(videos: [vid1])
        self.navigationController?.present(vc, animated: true, completion: nil)

        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeMovie as String]
        if #available(iOS 11.0, *) {
            imagePickerController.videoExportPreset = AVAssetExportPresetPassthrough
        } else {
            // Fallback on earlier versions
            // @TODO: Compression will happen here
            imagePickerController.videoQuality = .typeHigh
        }

        self.present(imagePickerController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let videoURL = info[UIImagePickerControllerMediaURL] as? URL
        print("videoURL:\(String(describing: videoURL))")
        self.dismiss(animated: true, completion: nil)

        let vid1 = VideoAsset(assetName: "", url: videoURL!)

        let vc = EditorViewController(videos: [vid1])
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}


// EditorViewController
class EditorViewController: UIViewController {
    var editorController: VideoEditorController

    required init(videos: [VideoAsset]) {
        self.editorController = VideoEditorController(videos: videos)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editorController.setupCanvasView(in: self.view, with: CGRect(x: 0, y: 0, width: self.view.width, height: self.view.width))

        editorController.setupControlsView(in: self.view, with: CGRect(x: 0, y: self.view.width, width: self.view.width, height: 44))

        let timelineHeight = self.view.height - self.editorController.canvasView.height - 44 // 44 is controls view height
        editorController.setupTimelineView(in: self.view, with: CGRect(x: 0, y: self.view.width + 44, width: self.view.width, height: timelineHeight))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// @TODO: Move this to canvas view
//extension ViewController: AssetPlayerDelegate {
//    func currentAssetDidChange(_ player: AssetPlayer) {
//
//    }
//
//    func playerIsSetup(_ player: AssetPlayer) {
//        guard player.duration != 0 && !player.duration.isNaN else {
//            return
//        }
//
//    }
//
//    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
//    }
//
//    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
//
//    }
//
//    func playerPlaybackDidEnd(_ player: AssetPlayer) {
//
//    }
//
//    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
//
//    }
//
//    func playerBufferTimeDidChange(_ player: AssetPlayer) {
//
//    }
//}

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

class CanvasView: UIView {
    weak var delegate: AssetPlayerDelegate?

    var assetPlayer: AssetPlayer?
    var playerView: PlayerView?

    override init(frame: CGRect) {
        super.init(frame: frame)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPlayer(with video: VideoAsset) {
        video.setupFrameFrom(self.frame)

        let asset = Asset(assetName: video.assetName, url: video.urlAsset.url)
        self.assetPlayer = AssetPlayer(asset: asset)
        self.assetPlayer?.isPlayingLocalVideo = true
        self.assetPlayer?.shouldLoop = true
        self.assetPlayer?.pause()

        self.playerView = assetPlayer?.playerView
        playerView?.frame = video.frame

        self.assetPlayer?.playerDelegate = self

        self.addSubview(self.playerView!)
    }
}

extension CanvasView: AssetPlayerDelegate {
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChangeInMilliseconds(player)
    }

    func currentAssetDidChange(_ player: AssetPlayer) {
        self.delegate?.currentAssetDidChange(player)
    }

    func playerIsSetup(_ player: AssetPlayer) {
//        guard player.duration != 0 && !player.duration.isNaN else {
//            return
//        }
        self.delegate?.playerIsSetup(player)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackStateDidChange(player)
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerCurrentTimeDidChange(player)
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.delegate?.playerPlaybackDidEnd(player)
    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        self.delegate?.playerIsLikelyToKeepUp(player)
    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
        self.delegate?.playerBufferTimeDidChange(player)
    }
}

// MARK: VideoEditorController

class VideoEditorController: NSObject {
    var videos: [VideoAsset]

    let canvasView = CanvasView()
    let controlsView = UIView()
    let timelineView = TimelineView()
    let layerManager = EditableLayerManager()

    init(videos: [VideoAsset]) {
        self.videos = videos

        super.init()

        layerManager.delegate = self
        timelineView.delegate = self
        canvasView.delegate = self
//        controlsView.delegate = self
    }

    func setupCanvasView(in view: UIView, with frame: CGRect) {
        self.canvasView.frame = frame
        view.addSubview(self.canvasView)

        self.canvasView.setupPlayer(with: videos.first!)
    }

    func setupTimelineView(in view: UIView, with frame: CGRect) {
        self.timelineView.frame = frame
        view.addSubview(self.timelineView)

        self.timelineView.setupTimeline()
    }

    func setupControlsView(in view: UIView, with frame: CGRect) {
        // Controls view
        controlsView.frame = frame

        let button = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: controlsView.height * 3, height: controlsView.height)))
        button.setTitle("Add Layer", for: .normal)
        button.addTarget(self, action: #selector(self.addLayerPressed), for: .touchUpInside)
        self.controlsView.addSubview(button)


        let playButtonWidth = controlsView.height * 3
        let playButton = UIButton(frame: CGRect(x: controlsView.center.x - playButtonWidth / 2, y: 0, width: playButtonWidth, height: controlsView.height))
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(self.playButtonPressed), for: .touchUpInside)
        self.controlsView.addSubview(playButton)

        view.addSubview(self.controlsView)
    }

    // @TODO: move this to controls view delegate
    @objc func playButtonPressed() {
        self.canvasView.assetPlayer?.play()
    }

    @objc func addLayerPressed() {
        // @TODO: Get current time from timeline
        self.layerManager.addLayer(atTime: self.timelineView.currentTimeForLinePosition)
    }
}

// Timeline View delegate
extension VideoEditorController: TimelineViewDelegate {
    func isScrolling(to time: Double) {
        self.canvasView.assetPlayer?.pause()
        self.canvasView.assetPlayer?.seekTo(interval: time)
    }

    func endScrolling(at time: Double) {
        // Set new start time
        self.canvasView.assetPlayer?.startTimeForLoop = time
        self.canvasView.assetPlayer?.seekTo(interval: time)
//        self.canvasView.assetPlayer?.play()
    }
}

// Layer Manager Delegate
extension VideoEditorController: EditableLayerManagerDelegate {
    func didAddLayer(_ layer: EditableLayer) {
        // Add layer to canvas
        self.canvasView.addSubview(layer)

        // Add layer to timeline
        self.timelineView.addLayerView(with: layer)
    }
}

// Canvas View Delegate
extension VideoEditorController: AssetPlayerDelegate {
    func currentAssetDidChange(_ player: AssetPlayer) {
//        self.delegate?.currentAssetDidChange(player)
    }

    func playerIsSetup(_ player: AssetPlayer) {
        //        guard player.duration != 0 && !player.duration.isNaN else {
        //            return
        //        }
//        self.delegate?.playerIsSetup(player)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
//        self.delegate?.playerPlaybackStateDidChange(player)
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
//        self.delegate?.playerCurrentTimeDidChange(player)
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        // Handle tracking for canvas view
        self.layerManager.handleTracking(for: player.currentTime)
        
        // Handle tracking for timeline view
        self.timelineView.handleTracking(for: player.currentTime)
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
//        self.delegate?.playerPlaybackDidEnd(player)
    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
//        self.delegate?.playerIsLikelyToKeepUp(player)
    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
//        self.delegate?.playerBufferTimeDidChange(player)
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
//        layer.backgroundColor = UIColor.random
        layer.setStartTime(to: startTime)
        layer.setEndTime(to: startTime + 1)

        layer.text = "NO"
        layer.textColor = .white
        layer.font = UIFont.boldSystemFont(ofSize: 40)
        layer.textAlignment = .center

        self.layers.append(layer)

        delegate?.didAddLayer(layer)
    }

    public func handleTracking(for millisecond: Double) {
        for layer in self.layers {
            layer.handlePlaying(at: millisecond)
        }
    }
}
