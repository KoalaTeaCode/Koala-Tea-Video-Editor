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

    var assetPlayer: AssetPlayer? = nil
    var playerView: PlayerView? = nil

    var images = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let avAsset = AVAsset(url: videoURL)

        let asset = Asset(assetName: "Test", url: videoURL)
        self.assetPlayer = AssetPlayer(asset: asset)
        assetPlayer?.playerDelegate = self
        assetPlayer?.isPlayingLocalVideo = true
        assetPlayer?.shouldLoop = true
        assetPlayer?.pause()

        playerView = assetPlayer?.playerView
        playerView?.backgroundColor = .red
        playerView?.frame = CGRect(x: 0, y: 0, width: self.view.width, height: self.view.width/(16/9))
        self.view.addSubview(playerView!)

        let tracks =  avAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = tracks.first!

        let divisor: CGFloat = 16/9

        let layerHeight = 173 / divisor
        let layerWidth = playerView!.frame.width

        let y = playerView!.frame.maxY - layerHeight

        let textLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: y, width: layerWidth, height: layerHeight),
                                                         text: "NO",
                                                         textColor: .white,
                                                         font: UIFont.systemFont(ofSize: 124.0 / divisor, weight: .bold))

        let longNoLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: (layerWidth / divisor) * 2, y: y, width: (layerWidth * 2) / divisor, height: layerHeight),
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

        textLayer.hideLayer(at: CACurrentMediaTime() + -1.0)
        textLayer.showLayer(at: CACurrentMediaTime() + (timePerFrame * 18), till: CACurrentMediaTime() + timePerFrame * 35)
        textLayer.showLayer(at: CACurrentMediaTime() + (timePerFrame * 107), till: CACurrentMediaTime() + timePerFrame * 114)
        textLayer.showLayer(at: CACurrentMediaTime() + (timePerFrame * 151), till: CACurrentMediaTime() + timePerFrame * 162)
        textLayer.showLayer(at: CACurrentMediaTime() + (timePerFrame * 169), till: CACurrentMediaTime() + timePerFrame * 180)
        textLayer.showLayer(at: CACurrentMediaTime() + (timePerFrame * 206), till: CACurrentMediaTime() + timePerFrame * 218)

        godLayer.hideLayer(at: CACurrentMediaTime() + -1.0)
        godLayer.showLayer(at: CACurrentMediaTime() + timePerFrame * 42, till: CACurrentMediaTime() + timePerFrame * 56)
        godLayer.showLayer(at: CACurrentMediaTime() + timePerFrame * 124, till: CACurrentMediaTime() + timePerFrame * 130)

        pleaseLayer.hideLayer(at: CACurrentMediaTime() + -1.0)
        pleaseLayer.showLayer(at: CACurrentMediaTime() + timePerFrame * 136, till: CACurrentMediaTime() + timePerFrame * 146)

        longNoLayer.hideLayer(at: CACurrentMediaTime() + -1.0)
        longNoLayer.showLayer(at: CACurrentMediaTime() + timePerFrame * 258, till: CACurrentMediaTime() + timePerFrame * 285)
        let duration = CACurrentMediaTime() + (timePerFrame * 300) - CACurrentMediaTime() + (timePerFrame * 258)
        longNoLayer.changePositionX(to: -8000, beginTime: CACurrentMediaTime() + timePerFrame * 258, duration: duration)
        longNoLayer.hideLayer(at: CACurrentMediaTime() + timePerFrame * 285)

        // Add CALayerToAdd to Parent Layer
        self.view.layer.addSublayer(textLayer)
        self.view.layer.addSublayer(godLayer)
        self.view.layer.addSublayer(pleaseLayer)
        self.view.layer.addSublayer(longNoLayer)

        let reader = try! AVAssetReader(asset: avAsset)

        // read video frames as BGRA
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        reader.add(trackReaderOutput)
        reader.startReading()

        var i = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            let image = VideoManager.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            images.append(image)
            i += 1
        }
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
        let frame = CGRect(x: 0, y: 240, width: self.view.width, height: 180/2)
        let scrollerView = FramesScrollerView(frame: frame, images: self.images, framerate: 30.0, videoDuration: player.duration)
        scrollerView.delegate = self
        self.view.addSubview(scrollerView)
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
