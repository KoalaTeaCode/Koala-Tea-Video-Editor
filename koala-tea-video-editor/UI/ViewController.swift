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

protocol EditableLayerProtocol {
    var startTime: Double { get }
    var endTime: Double { get }
    var frame: CGRect { get set }
    func setStartTime(to time: Double)
    func setEndTime(to time: Double)
    func frameWasSet()
    func handlePlaying(at time: Double)
}

class EditableLayer: EditableLayerProtocol {
    var frame: CGRect {
        didSet {
            self.frameWasSet()
        }
    }

    var startTime: Double

    var endTime: Double

    init() {
        self.frame = .zero
        self.startTime = 0
        self.endTime = 0
    }

    func setStartTime(to time: Double) {
        self.startTime = time
    }

    func setEndTime(to time: Double) {
        self.endTime = time
    }

    func frameWasSet() {}

    /// Function to handle animations in the layer by the time of a video
    func handlePlaying(at time: Double) {}
}

class CATextEditableLayer: EditableLayer {
    var caTextLayer: CATextLayer
    var animations: [CABasicAnimation] = []
    var visible: Bool = false

    override init() {
        self.caTextLayer = CoreLayerManager.createTextLayer(frame: .zero, text: "Your Text Here")
        self.caTextLayer.opacity = 0

        super.init()
    }

    func setText(to text: String) {
        self.caTextLayer.string = text
    }

    func setFont(to font: UIFont) {
        self.caTextLayer.font = font
        self.caTextLayer.fontSize = font.pointSize

        // @TODO: Set frame height accordingly?
    }

    func setTextColor(to color: UIColor) {
        self.caTextLayer.foregroundColor = color.cgColor
    }

    override func setStartTime(to startTime: Double) {
        super.setStartTime(to: startTime)

        // Create show animation
        let animation = CABasicAnimation.showLayerAnimation(at: startTime)
        
        // Add animation to [animations] to be used on export
        self.animations.append(animation)
    }

    override func setEndTime(to endTime: Double) {
        super.setEndTime(to: endTime)

        // Create hide animation
        let animation = CABasicAnimation.hideLayerAnimation(at: endTime)

        // Add animation to [animations] to be used on export
        self.animations.append(animation)
    }

    func addToSuperview(_ superView: UIView) {
        superView.layer.addSublayer(self.caTextLayer)
    }

    override func frameWasSet() {
        self.caTextLayer.frame = self.frame
    }

    override func handlePlaying(at time: Double) {
        super.handlePlaying(at: time)

        guard time >= startTime && time <= endTime else {
            hideLayer()
            return
        }

        showLayer()
    }

    private func showLayer() {
        guard !self.visible else {
            return
        }
        self.visible = true

        let animation = CABasicAnimation.showLayerAnimation()

        self.caTextLayer.add(animation, forKey: "show")
    }

    private func hideLayer() {
        guard self.visible else {
            return
        }
        self.visible = false

        let animation = CABasicAnimation.hideLayerAnimation()

        self.caTextLayer.add(animation, forKey: "hide")
    }
}

class ViewController: UIViewController {

    var assetPlayer: AssetPlayer?
    var playerView: PlayerView?
    lazy var canvasView: CanvasView = {
        return CanvasView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: self.view.width))
    }()

    var images = [UIImage]()

    let tlayer = CATextEditableLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        canvasView.center = self.view.center
        canvasView.clipsToBounds = true
        canvasView.backgroundColor = .black
        self.view.addSubview(canvasView)

        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let asset = Asset(assetName: "Test", url: videoURL)
        self.assetPlayer = AssetPlayer(asset: asset)
        assetPlayer?.playerDelegate = self
        assetPlayer?.isPlayingLocalVideo = true
        assetPlayer?.shouldLoop = true

        playerView = assetPlayer?.playerView
        playerView?.frame = CGRect(x: 0, y: 0, width: canvasView.height * (16/9), height: canvasView.height)

        canvasView.addSubview(playerView!)

        tlayer.setText(to: "TESTING")
        tlayer.setFont(to: .italicSystemFont(ofSize: 150))
        tlayer.setTextColor(to: .red)
        tlayer.frame = CGRect(x: 0, y: 88, width: 200, height: 200)
        tlayer.setStartTime(to: 3)
        tlayer.setEndTime(to: 6)
        tlayer.addToSuperview(self.canvasView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController,
                               didSaveEditedVideoToPath editedVideoPath: String) {
        print(editedVideoPath)
        print("saved!")
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        print("cancel")
    }

    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("did fail")
    }
}

extension ViewController: AssetPlayerDelegate {
    func currentAssetDidChange(_ player: AssetPlayer) {

    }

    func playerIsSetup(_ player: AssetPlayer) {
        guard player.duration != 0 && !player.duration.isNaN else {
            return
        }
//        let frame = CGRect(x: 0, y: 240, width: self.view.width, height: 180/2)
//        let scrollerView = FramesScrollerView(frame: frame, images: self.images, framerate: 30.0, videoDuration: player.duration)
//        scrollerView.delegate = self
//        self.view.addSubview(scrollerView)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.tlayer.handlePlaying(at: player.currentTime)
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {

    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {

    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {

    }
}

extension ViewController: FramesScrollerViewDelegate {
    func isScrolling(to time: Double) {
        self.assetPlayer?.pause()
        self.assetPlayer?.seekTo(interval: time)
    }

    func endScrolling(at time: Double) {
        // Set new start time
        self.assetPlayer?.startTimeForLoop = time
        self.assetPlayer?.seekTo(interval: time)
        self.assetPlayer?.play()
    }
}
