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

class ViewController: UIViewController {

    var assetPlayer: AssetPlayer?
    var playerView: PlayerView?
    lazy var canvasView: CanvasView = {
        return CanvasView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: self.view.width))
    }()

    var images = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let avAsset = AVAsset(url: videoURL)

        canvasView.center = self.view.center
        canvasView.clipsToBounds = true
        canvasView.backgroundColor = .black
        self.view.addSubview(canvasView)

        let asset = Asset(assetName: "Test", url: videoURL)
        self.assetPlayer = AssetPlayer(asset: asset)
        assetPlayer?.playerDelegate = self
        assetPlayer?.isPlayingLocalVideo = true
        assetPlayer?.shouldLoop = true

        playerView = assetPlayer?.playerView
//        playerView?.frame = CGRect(x: 0, y: (canvasView.height/2) - (210.94/2), width: canvasView.width, height: 210.94)
        playerView?.frame = CGRect(x: 0, y: 0, width: canvasView.height * (16/9), height: canvasView.height)

        canvasView.addSubview(playerView!)

        let tracks =  avAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = tracks.first!

        let divisor: CGFloat = 3.4133333

        let layerHeight: CGFloat = 173 / divisor
        let playerFrameWidth = canvasView.contentView.frame.width
        let layerWidth = playerFrameWidth

        let y = canvasView.contentView.frame.maxY - layerHeight

        let textLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: y, width: layerWidth, height: layerHeight),
                                                         text: "NO",
                                                         textColor: .white,
                                                         font: UIFont.systemFont(ofSize: 124.0 / divisor, weight: .bold))

        let longNoLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: layerWidth, y: y, width: (layerWidth * 2), height: layerHeight),
                                                           text: "NO" + String(repeating: "O", count: 200),
                                                           textColor: .white,
                                                           font: UIFont.systemFont(ofSize: 124 / divisor, weight: .bold))

        let godLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: y, width: layerWidth, height: layerHeight),
                                                        text: "GOD",
                                                        textColor: .white,
                                                        font: UIFont.systemFont(ofSize: 124 / divisor, weight: .bold))

        let pleaseLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: y, width: layerWidth, height: layerHeight),
                                                           text: "PLEASE",
                                                           textColor: .white,
                                                           font: UIFont.systemFont(ofSize: 124 / divisor, weight: .bold))


        // @TODO: figure out variable framerate checking
        let frameRate = videoTrack.nominalFrameRate
        let timePerFrame: Double = Double(1.0 / frameRate)

        // Get current Media Time for start of all animations
        // Current Media Time is used only when displaying on device
        let currentMediaTime = CACurrentMediaTime()

        textLayer.hideLayer(at: -1.0, currentMediaTime: currentMediaTime)
        textLayer.showLayer(at: timePerFrame * (18 + 6), till: timePerFrame * (35 + 6), currentMediaTime: currentMediaTime)
        textLayer.showLayer(at: timePerFrame * (107 + 6), till: timePerFrame * (114 + 6), currentMediaTime: currentMediaTime)
        textLayer.showLayer(at: timePerFrame * (151 + 6), till: timePerFrame * (162 + 6), currentMediaTime: currentMediaTime)
        textLayer.showLayer(at: timePerFrame * (169 + 6), till: timePerFrame * (180 + 6), currentMediaTime: currentMediaTime)
        textLayer.showLayer(at: timePerFrame * (206 + 6), till: timePerFrame * (218 + 6), currentMediaTime: currentMediaTime)

        godLayer.hideLayer(at: -1.0, currentMediaTime: currentMediaTime)
        godLayer.showLayer(at: timePerFrame * (42 + 6), till: timePerFrame * (56 + 6), currentMediaTime: currentMediaTime)
        godLayer.showLayer(at: timePerFrame * (124 + 6), till: timePerFrame * (130 + 6), currentMediaTime: currentMediaTime)

        pleaseLayer.hideLayer(at: -1.0, currentMediaTime: currentMediaTime)
        pleaseLayer.showLayer(at: timePerFrame * (136 + 6), till: timePerFrame * (146 + 6), currentMediaTime: currentMediaTime)

        longNoLayer.hideLayer(at: -1.0, currentMediaTime: currentMediaTime)
        longNoLayer.showLayer(at: timePerFrame * (258 + 6), till: timePerFrame * (285 + 6), currentMediaTime: currentMediaTime)

        let duration = (timePerFrame * (300 + 6)) - (timePerFrame * (258 + 6))
        longNoLayer.changePositionX(to: -300, beginTime: timePerFrame * (258 + 6), duration: duration, currentMediaTime: currentMediaTime)
        longNoLayer.hideLayer(at: timePerFrame * (285 + 6), currentMediaTime: currentMediaTime)

        // Add CALayerToAdd to Parent Layer
        canvasView.layer.addSublayer(textLayer)
        canvasView.layer.addSublayer(godLayer)
        canvasView.layer.addSublayer(pleaseLayer)
        canvasView.layer.addSublayer(longNoLayer)

        self.images = VideoManager.getAllFramesAsUIImages(for: asset.urlAsset)!

//        //@TODO: end reading

//        VideoManager.exportVideo(from: AVAsset(url: videoURL),
//                                 avPlayerFrame: playerView!.frame,
//                                 croppedViewFrame: canvasView.frame,
//                                 caLayers: [textLayer, godLayer, pleaseLayer, longNoLayer],
//                                 currentMediaTimeUsed: currentMediaTime)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: AssetPlayerDelegate {
    func currentAssetDidChange(_ player: AssetPlayer) {

    }

    func playerIsSetup(_ player: AssetPlayer) {
        assetPlayer?.pause()
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

public class CanvasView: UIView {
    let contentView: UIView

    override public init(frame: CGRect) {
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))

        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
