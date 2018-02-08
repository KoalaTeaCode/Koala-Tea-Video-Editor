//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

fileprivate enum VideoManagerError: Error {
    case FailedError
    case CancelledError
    case UnknownError
    case NoFirstVideoTrack
}

enum VideoExportSizes {
    case _1080x1080
    case _1280x720
    case _720x1280
    case _1920x1080
    case _1080x1920
}

extension VideoExportSizes {
    typealias RawValue = CGSize

    var rawValue: RawValue {
        switch self {
        case ._1080x1080:
            return CGSize(width: 1080, height: 1080)
        case ._1280x720:
            return CGSize(width: 1280, height: 720)
        case ._720x1280:
            return CGSize(width: 720, height: 1280)
        case ._1920x1080:
            return CGSize(width: 1920, height: 1080)
        case ._1080x1920:
            return CGSize(width: 1080, height: 1920)
        }
    }
}

public class VideoManager {
    private class func getScaledLayers(for layers: [CALayer], widthMultiplier: CGFloat, heightMultiplier: CGFloat, currentMediaTimeUsed: Double) -> [CALayer] {
        var scaledLayers = [CALayer]()

        for layer in layers {
            // @TODO: add layer is check
            // layer is CATextLayer

            let thisLayer = layer as! CATextLayer
            thisLayer.removeAnimationsCurrentMediaTimeFor(currentMediaTimeUsed: currentMediaTimeUsed)

            let scaledWidth = thisLayer.frame.width * widthMultiplier
            // * size. / video player show height or width
            let scaledHeight = thisLayer.frame.height * heightMultiplier

            //@TODO: Figure out best way to scale font size
            thisLayer.fontSize = thisLayer.fontSize * heightMultiplier
            thisLayer.backgroundColor = UIColor.red.cgColor

            let scaledX = thisLayer.frame.minX * widthMultiplier
            let scaledY = thisLayer.frame.minY * heightMultiplier

            thisLayer.frame = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)

            scaledLayers.append(thisLayer)
        }

        return scaledLayers
    }

    public class func createAnimationLayer(caLayers: [CALayer], currentMediaTimeUsed: Double, completion: @escaping () -> ()) {
        ////////////////////////////
        //MARK: Video Track Getter//
        ////////////////////////////
        
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let asset = AVAsset(url: videoURL)
        
        let avMutableComposition = AVMutableComposition()
        
        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = track.first! as AVAssetTrack
        let timerange = CMTimeRangeMake(kCMTimeZero, asset.duration)

        let compositionVideoTrack: AVMutableCompositionTrack = avMutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: kCMTimeZero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }

        //@TODO: This should be size of avplayer or size we want the video to be?
        let size = videoTrack.naturalSize

        /*
         MARK: Video Layer
         This layer determines the size of the video layer and should be set to the original video's naturalSize
         */
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        /*
         MARK: Parent Layer
         This layer is for adding all of our CALayers that will go over the video layer
         */
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.isGeometryFlipped = true
        parentlayer.addSublayer(videolayer)

        /*
         MARK: Add CALayers To Parent View
         */

        // @TODO: Make this a completion handler
        // sometimes this gets skipped over
        for layer in caLayers {
            // @TODO: add layer is check
            // layer is CATextLayer

            let thisLayer = layer as! CATextLayer
            thisLayer.removeAnimationsCurrentMediaTimeFor(currentMediaTimeUsed: currentMediaTimeUsed)

            let scaledWidth = thisLayer.frame.width * (size.width / 375)

            // * size. / video player show height or width
            let scaledHeight = thisLayer.frame.height * (size.height / 210.9375)

            //@TODO: Figure out best way to scale font size
            thisLayer.fontSize = thisLayer.fontSize * (size.height / 210.9375)
            thisLayer.backgroundColor = UIColor.red.cgColor

            let scaledX = thisLayer.frame.minX * (size.width / 375)
            let scaledY = thisLayer.frame.minY * (size.height / 210.9375)

            thisLayer.frame = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)
            parentlayer.addSublayer(layer)
        }

        /*
         MARK: Animation Sync Layer
         */
        let avSynchronizedLayer = AVSynchronizedLayer()
        // Add parent layer to contents
        avSynchronizedLayer.contents = parentlayer
        avSynchronizedLayer.frame = parentlayer.frame
        avSynchronizedLayer.masksToBounds = true
        
        // Add avSynchronizedLayer to Parent Layer
        parentlayer.addSublayer(avSynchronizedLayer)

        /*
         MARK: Video Composition
         */
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = CGSize(width: size.width, height: size.height)
        avMutableVideoComposition.renderScale = 1.0
        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avMutableComposition.duration)

        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)


        // @TODO: TO SCALE
        // -> Set avMutableVideoComposition.renderSize to the entire video size you want
        // -> set layer instructions transform to final layer size

        // Original rect of video -> cropped rect
//        let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: 1280, height: 720), toRect: CGRect(x: -200, y: 0, width: 1280, height: 720))
//        layerinstruction.setTransform(transform, at: kCMTimeZero)
        layerinstruction.setTransform(videoTrack.preferredTransform, at: kCMTimeZero)

        instruction.layerInstructions = [layerinstruction]
        avMutableVideoComposition.instructions = [instruction]

        /*
         MARK: Video Exporter
         */
        VideoManager.exportVideoToDiskFrom(avMutableComposition: avMutableComposition,
                                 avMutatableVideoComposition: avMutableVideoComposition,
        progress: { (progress) in
            print(progress)
        }, success: {
            completion()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}

// Multiple assets
extension VideoManager {
    private static func exportVideoToDiskFrom(avMutableComposition: AVMutableComposition,
                                             avMutatableVideoComposition: AVMutableVideoComposition,
                                             progress: @escaping (Float) -> (),
                                             success: @escaping () -> (),
                                             failure: @escaping (Error) -> ()) {
        guard let fileURL = FileHelpers.getDocumentsURL(for: "test", extension: "mp4") else {
            return
        }

        // Remove any file at URL
        // If file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)

        // Create AVAssetExportSession
        guard let assetExport = AVAssetExportSession(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        assetExport.videoComposition = avMutatableVideoComposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.outputURL = fileURL

        // Schedule timer for sending progress
        var timer: Timer? = nil

        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                progress(assetExport.progress)
            })
        } else {
            // Fallback on earlier versions
        }

        assetExport.exportAsynchronously(completionHandler: {
            timer?.invalidate()
            //@TODO: Show status or pass it back in completion
            switch assetExport.status {
            case .completed:
                print("success")
                success()
                print(fileURL)
                break
            case .exporting:
                assertionFailure("exporting")
                break
            case .waiting:
                assertionFailure("waiting")
                break
            case .cancelled:
                assertionFailure("cancelled")
                failure(VideoManagerError.CancelledError)
                break
            case .failed:
                assertionFailure("failed: \(assetExport.error!)")
                failure(VideoManagerError.FailedError)
                break
            case .unknown:
                assertionFailure("unknown")
                failure(VideoManagerError.UnknownError)
                break
            }
        })
    }

    public static func exportMergedVideo(with assets: [VideoAsset], croppedViewFrame: CGRect, finalExportSize: VideoExportSizes) {
        let exportVideoSize = finalExportSize.rawValue

        guard croppedViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Seleected export size's aspect ration does not equal Cropped View Frame's aspect ratio")
            return
        }

        // *Cropped view has to be same aspect ratio as export video size
        let heightMultiplier: CGFloat = exportVideoSize.height / croppedViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / croppedViewFrame.width

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        //// Create video tracks ////
        let mainInstruction = AVMutableVideoCompositionInstruction()

        var totalVideoDuration = kCMTimeZero
        for asset in assets {
            totalVideoDuration = CMTimeAdd(totalVideoDuration, asset.timeRange.duration)
        }

        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalVideoDuration)

        // 2 - Add all asset tracks to mixComposition
        // 3 - Get instructions for all assets
        let instructions = self.add(assets: assets, to: mixComposition, widthMultiplier: widthMultiplier, heightMultiplier: heightMultiplier)

        // 4 - Add instructions to mainInstruction
        mainInstruction.layerInstructions = instructions
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        //@TODO: Add framerate
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = exportVideoSize

        // - Audio track
        if let loadedAudioAsset = assets.first?.urlAsset {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(2.0, 1)),
                                                of: loadedAudioAsset.tracks(withMediaType: .audio).first!,
                                                at: kCMTimeZero)
            } catch _ {
                print("Failed to load audio track")
            }
        }

        // - Export
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition,
                                   avMutatableVideoComposition: avMutableVideoComposition,
                                   progress: { (progress) in
                                    print(progress)
        }, success: {
            //                completion()
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    private static func add(assets: [VideoAsset], to composition: AVMutableComposition, widthMultiplier: CGFloat, heightMultiplier: CGFloat) -> [AVMutableVideoCompositionLayerInstruction] {
        var instructions: [AVMutableVideoCompositionLayerInstruction] = []

        var nextAssetsStartTime = kCMTimeZero

        for (index, asset) in assets.enumerated() {
            let track = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                let timeRange = asset.timeRange
                guard let firstTrack = asset.urlAsset.tracks(withMediaType: AVMediaType.video).first else {
                    throw VideoManagerError.NoFirstVideoTrack
                }

                var startTime = kCMTimeZero

                if index != 0 {
                    let previousAsset = assets[index - 1]
                    nextAssetsStartTime = nextAssetsStartTime + previousAsset.timeRange.duration
                    startTime = nextAssetsStartTime
                }

                try track?.insertTimeRange(timeRange, of: firstTrack, at: startTime)

                let instruction = videoCompositionInstructionForTrack(track: track!, asset: asset, widthMultiplier: widthMultiplier, heightMultiplier: heightMultiplier)

                instruction.setOpacity(0.0, at: startTime + timeRange.duration)

                instructions.append(instruction)
            } catch _ {
                assertionFailure("Failed to load first track")
            }
        }

        return instructions
    }

    private static func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: VideoAsset, widthMultiplier: CGFloat, heightMultiplier: CGFloat) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.urlAsset.tracks(withMediaType: AVMediaType.video).first!

        // @TODO: check if we need asset info or if it works
//        let transform = assetTrack.preferredTransform
//        let assetInfo = orientationFromTransform(transform: transform)

        let scaledX: CGFloat = asset.frame.minX * widthMultiplier
        let scaledY: CGFloat = asset.frame.minY * heightMultiplier

        var scaledWidth = asset.frame.width * widthMultiplier
        var scaledHeight = asset.frame.height * heightMultiplier

        let isPortrait = assetTrack.naturalSize.height > assetTrack.naturalSize.width

        if isPortrait {
            scaledWidth = asset.frame.width * heightMultiplier
            scaledHeight = asset.frame.height * widthMultiplier
        }

        let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height),
                                          toRect: CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight))
        instruction.setTransform(transform, at: kCMTimeZero)
        return instruction
    }

    // @TODO: check if this works
//    private static func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
//        var assetOrientation = UIImageOrientation.up
//        var isPortrait = false
//        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
//            assetOrientation = .right
//            isPortrait = true
//        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
//            assetOrientation = .left
//            isPortrait = true
//        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
//            assetOrientation = .up
//        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
//            assetOrientation = .down
//        }
//        return (assetOrientation, isPortrait)
//    }
}
