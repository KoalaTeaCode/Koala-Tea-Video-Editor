//
//  VideoEditorViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/19/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import KoalaTeaPlayer

class VideoEditorViewController: UIViewController {
    let videoAsset: VideoAsset
    let assetPlayer: AssetPlayer
    let playerView: PlayerView?

    lazy var canvasView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: self.view.width))
    }()

    var containerView: LayerContainerViewOLD = LayerContainerViewOLD(frame: .zero, layerViews: [])

    var buttonView: UIView = UIView()

    required init(videoAsset: VideoAsset) {
        self.videoAsset = videoAsset
        let asset = Asset(assetName: videoAsset.assetName, url: videoAsset.urlAsset.url)
        self.assetPlayer = AssetPlayer(asset: asset)
        self.playerView = assetPlayer.playerView

        super.init(nibName: nil, bundle: nil)

        canvasView.frame = CGRect(x: 0, y: 0, width: 375, height: 375)
        canvasView.clipsToBounds = true
        canvasView.backgroundColor = .black
        self.view.addSubview(canvasView)

        assetPlayer.playerDelegate = self
        assetPlayer.isPlayingLocalVideo = true
        assetPlayer.shouldLoop = true
        assetPlayer.pause()

        guard let playerView = playerView else {
            assertionFailure("PlayerView should never be nil here")
            // Handle error
            return
        }

        playerView.frame = CGRect(origin: .zero, size: CanvasFrameSizes._16x9(forSize: canvasView.size).rawValue)
        playerView.center = self.canvasView.center

        self.canvasView.addSubview(playerView)

        self.buttonView.frame = CGRect(x: 0, y: self.canvasView.frame.maxY, width: 375, height: 40)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        button.setTitle("Add", for: .normal)
        button.addTarget(self, action: #selector(self.addButtonPressed), for: .touchUpInside)
        self.buttonView.addSubview(button)
        self.buttonView.backgroundColor = .blue
        self.view.addSubview(self.buttonView)

        self.setupContainerView()
    }

    @objc func addButtonPressed() {
        self.addLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupContainerView() {
//        let views = [
//            LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
//        ]

        let containerFrame = CGRect(x: 0, y: self.canvasView.frame.maxY + 40, width: 375, height: 200)
        self.containerView = LayerContainerViewOLD(frame: containerFrame, layerViews: [])
        self.view.addSubview(containerView)
    }

    func addLayer() {
        let duration = self.videoAsset.urlAsset.duration.seconds
        let textLayer = EditableLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        textLayer.backgroundColor = UIColor.random
//        textLayer.text = "TESTING"
//        textLayer.font = .italicSystemFont(ofSize: 70)
//        textLayer.textColor = .red
        textLayer.setStartTime(to: 3)
        textLayer.setEndTime(to: 6)

        let layerSliderView = LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)

        self.containerView.addSubviewToStackView(layerSliderView)

        self.canvasView.addSubview(textLayer)
    }
}

extension VideoEditorViewController: AssetPlayerDelegate {
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
        // Handle layers changing
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {

    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {

    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {

    }
}
