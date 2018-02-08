//
//  AVAssetExtensions.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

extension AVAsset {
    public func getFirstVideoTrack() -> AVAssetTrack? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            assertionFailure("Failure getting first track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }

    public func getAllFramesAsUIImages() -> [UIImage]? {
        var images: [UIImage] = []

        // Frame Reader
        let reader = try! AVAssetReader(asset: self)

        guard let firstTrack = self.getFirstVideoTrack() else {
            return nil
        }

        // read video frames as BGRA
        let trackReaderOutput = AVAssetReaderTrackOutput(track: firstTrack,
                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        reader.add(trackReaderOutput)
        reader.startReading()

        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            let image = CMBufferHelper.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            images.append(image)
        }

        return images
    }
}
