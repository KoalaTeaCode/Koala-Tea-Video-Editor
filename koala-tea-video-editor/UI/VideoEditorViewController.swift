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

        self.setupContainerView()
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
        let duration = self.videoAsset.urlAsset.duration.seconds
        let textLayer = CATextEditableLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        textLayer.setText(to: "TESTING")
        textLayer.setFont(to: .italicSystemFont(ofSize: 70))
        textLayer.setTextColor(to: .red)
        textLayer.setStartTime(to: 3)
        textLayer.setEndTime(to: 6)


        let views = [
            LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
            ,LayerSliderView(frame: .zero, editableLayer: textLayer, assetDuration: duration)
        ]

        for view in views {
            view.editableLayer.addToSuperview(self.view)
        }

        let containerFrame = CGRect(x: 0, y: self.canvasView.frame.maxY + 40, width: 375, height: 200)
        let containerView = LayerContainerView(frame: containerFrame, layerViews: views)
        self.view.addSubview(containerView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            for view in views {
                view.editableLayer.frame = CGRect(x: 130, y: 30, width: 200, height: 200)
            }
        }
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
