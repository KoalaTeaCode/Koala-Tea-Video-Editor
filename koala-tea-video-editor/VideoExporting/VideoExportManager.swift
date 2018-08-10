//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit
import Photos // @TODO: Remove photos from here

/// Exporter for VideoAssets
public class VideoExportManager {
    private enum VideoManagerError: Error {
        case FailedError
        case CancelledError
        case UnknownError
        case NoFirstVideoTrack
    }

    /**
     Supported Final Video Sizes

     - _1080x1080: 1080 width by 1080 height
     - _1280x720: 1280 width by 720 height
     - _720x1280: 720 width by 1280 height
     - _1920x1080: 1920 width by 1080 height
     - _1080x1920: 1080 width by 1920 height
     */
    public enum VideoExportSizes {
        case _1080x1080
        case _1024x1024
        case _1280x720
        case _720x1280
        case _1920x1080
        case _1080x1920
        case _1280x1024_twitter

        typealias RawValue = CGSize

        var rawValue: RawValue {
            switch self {
            case ._1080x1080:
                return CGSize(width: 1080, height: 1080)
            case ._1024x1024:
                return CGSize(width: 1024, height: 1024)
            case ._1280x720:
                return CGSize(width: 1280, height: 720)
            case ._720x1280:
                return CGSize(width: 720, height: 1280)
            case ._1920x1080:
                return CGSize(width: 1920, height: 1080)
            case ._1080x1920:
                return CGSize(width: 1080, height: 1920)
            case ._1280x1024_twitter:
                return CGSize(width: 1280, height: 1024)
            }
        }
    }

    private class func getScaledLayers(for layers: [CALayer], widthMultiplier: CGFloat, heightMultiplier: CGFloat, currentMediaTimeUsed: Double) -> [CALayer] {
        var scaledLayers = [CALayer]()

        for layer in layers {
            // @TOOD: Find other class specific edits that need to be made
            switch layer.self {
            case is CATextLayer:
                // @TODO: Figure out best way to scale font size
                // @TODO: Does this add to layer?
                let thisLayer = layer as! CATextLayer
                thisLayer.fontSize = thisLayer.fontSize * heightMultiplier
                break
            default:
                break
            }

            layer.backgroundColor = UIColor.red.cgColor

            let scaledWidth = layer.frame.width * widthMultiplier
            let scaledHeight = layer.frame.height * heightMultiplier
            let scaledX = layer.frame.minX * widthMultiplier
            let scaledY = layer.frame.minY * heightMultiplier

            layer.frame = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)

            scaledLayers.append(layer)
        }

        return scaledLayers
    }


    // @TODO: Old method but has CALayer info
//    public class func createAnimationLayer(caLayers: [CALayer], currentMediaTimeUsed: Double, completion: @escaping () -> ()) {
//        ////////////////////////////
//        //MARK: Video Track Getter//
//        ////////////////////////////
//
//        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
//        let asset = AVAsset(url: videoURL)
//
//        let avMutableComposition = AVMutableComposition()
//
//        let track =  asset.tracks(withMediaType: AVMediaType.video)
//        let videoTrack: AVAssetTrack = track.first! as AVAssetTrack
//        let timerange = CMTimeRangeMake(kCMTimeZero, asset.duration)
//
//        let compositionVideoTrack: AVMutableCompositionTrack = avMutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
//
//        do {
//            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: kCMTimeZero)
//            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
//        } catch {
//            print(error)
//        }
//
//        //@TODO: This should be size of avplayer or size we want the video to be?
//        let size = videoTrack.naturalSize
//
//        /*
//         MARK: Video Layer
//         This layer determines the size of the video layer and should be set to the original video's naturalSize
//         */
//        let videolayer = CALayer()
//        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//
//        /*
//         MARK: Parent Layer
//         This layer is for adding all of our CALayers that will go over the video layer
//         */
//        let parentlayer = CALayer()
//        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        parentlayer.isGeometryFlipped = true
//        parentlayer.addSublayer(videolayer)
//
//        /*
//         MARK: Add CALayers To Parent View
//         */
//
//        // @TODO: Make this a completion handler
//        // sometimes this gets skipped over
//        for layer in caLayers {
//            // @TODO: add layer is check
//            // layer is CATextLayer
//
//            let thisLayer = layer as! CATextLayer
//            thisLayer.removeAnimationsCurrentMediaTimeFor(currentMediaTimeUsed: currentMediaTimeUsed)
//
//            let scaledWidth = thisLayer.frame.width * (size.width / 375)
//
//            // * size. / video player show height or width
//            let scaledHeight = thisLayer.frame.height * (size.height / 210.9375)
//
//            //@TODO: Figure out best way to scale font size
//            thisLayer.fontSize = thisLayer.fontSize * (size.height / 210.9375)
//            thisLayer.backgroundColor = UIColor.red.cgColor
//
//            let scaledX = thisLayer.frame.minX * (size.width / 375)
//            let scaledY = thisLayer.frame.minY * (size.height / 210.9375)
//
//            thisLayer.frame = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)
//            parentlayer.addSublayer(layer)
//        }
//
//        /*
//         MARK: Animation Sync Layer
//         */
//        let avSynchronizedLayer = AVSynchronizedLayer()
//        // Add parent layer to contents
//        avSynchronizedLayer.contents = parentlayer
//        avSynchronizedLayer.frame = parentlayer.frame
//        avSynchronizedLayer.masksToBounds = true
//
//        // Add avSynchronizedLayer to Parent Layer
//        parentlayer.addSublayer(avSynchronizedLayer)
//
//        /*
//         MARK: Video Composition
//         */
//        let avMutableVideoComposition = AVMutableVideoComposition()
//        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
//        avMutableVideoComposition.renderSize = CGSize(width: size.width, height: size.height)
//        avMutableVideoComposition.renderScale = 1.0
//        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
//
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avMutableComposition.duration)
//
//        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//
//
//        // @TODO: TO SCALE
//        // -> Set avMutableVideoComposition.renderSize to the entire video size you want
//        // -> set layer instructions transform to final layer size
//
//        // Original rect of video -> cropped rect
////        let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: 1280, height: 720), toRect: CGRect(x: -200, y: 0, width: 1280, height: 720))
////        layerinstruction.setTransform(transform, at: kCMTimeZero)
//        layerinstruction.setTransform(videoTrack.preferredTransform, at: kCMTimeZero)
//
//        instruction.layerInstructions = [layerinstruction]
//        avMutableVideoComposition.instructions = [instruction]
//
//        // Export to disk
//        self.exportVideoToDiskFrom(avMutableComposition: avMutableComposition,
//                                 avMutatableVideoComposition: avMutableVideoComposition,
//        progress: { (progress) in
//            print(progress)
//        }, success: {
//            completion()
//        }) { (error) in
//            print(error.localizedDescription)
//        }
//    }
}

// Multiple assets
extension VideoExportManager {
    /**
     Exports a video to the disk from AVMutableComposition and AVMutableVideoComposition.

     - Parameters:
         - avMutableComposition: Layer composition of everything except video
         - avMutatableVideoComposition: Video composition

         - progress: Returns progress every second.
         - success: Completion for when the video is saved successfully.
         - failure: Completion for when the video failed to save.
     */
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
                print(fileURL, "success file url")
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }) { saved, error in
                    if saved {
                        let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
//                        self.present(alertController, animated: true, completion: nil)
                    }
                }
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

    /**
     Public function to take in VideoAssets, merge them, and save them to the disk.

     - Parameters:
        - assets: VideoAssets that will be merged.
        - canvasViewFrame: The frame for the CanvasView in our VideoProject.
        - finalExportSize: The export size for the final video.

        - progress: Returns progress every second.
        - success: Completion for when the video is saved successfully.
        - failure: Completion for when the video failed to save.
     */
    public static func exportMergedVideo(with assets: [VideoAsset],
                                         canvasViewFrame: CGRect,
                                         finalExportSize: VideoExportSizes) {
        let exportVideoSize = finalExportSize.rawValue

        // Canvas view has to be same aspect ratio as export video size
        guard canvasViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Seleected export size's aspect ration does not equal Cropped View Frame's aspect ratio")
            return
        }

        // Multipliers to scale height and width to final export size
        let heightMultiplier: CGFloat = exportVideoSize.height / canvasViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / canvasViewFrame.width

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
        // @TODO: Add framerate
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = exportVideoSize


        //@TODO: Clean this up
//        /*
//         MARK: Parent Layer
//         This layer is for adding all of our CALayers that will go over the video layer
//         */
//        let parentlayer = CALayer()
//        parentlayer.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
//        parentlayer.isGeometryFlipped = true
////        parentlayer.addSublayer(videolayer)
//
//        let label = UILabel(text: "TESTINGTESTINGTESTINGTESTINGTESTING")
//        label.font = UIFont.boldSystemFont(ofSize: 40)
//        label.frame = CGRect(x: 0, y: 0, width: 700, height: 200)
//        label.textColor = .red
//        label.backgroundColor = .yellow
//        label.layer.display()
//
//        let view = UIView()
//        view.frame = CGRect(x: 50, y: 50, width: 200, height: 200)
//        view.backgroundColor = .yellow
//
//        let layer = CALayer()
//        layer.backgroundColor = UIColor.red.cgColor
//        layer.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
//
//        parentlayer.addSublayer(label.layer)
////        parentlayer.addSublayer(view.layer)
//
//        /*
//         MARK: Animation Sync Layer
//         */
//        let avSynchronizedLayer = AVSynchronizedLayer()
//        // Add parent layer to contents
//        avSynchronizedLayer.contents = parentlayer
//        avSynchronizedLayer.frame = parentlayer.frame
//        avSynchronizedLayer.masksToBounds = true
//
//        // Add avSynchronizedLayer to Parent Layer
//        parentlayer.addSublayer(avSynchronizedLayer)
//
//
//        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: parentlayer, in: parentlayer)

        // @TODO: Add audio tracks
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

    /**
     Adds assets to the AVMutableComposition and returns an array of AVMutableVideoCompositionLayerInstruction.

     - Parameters:
         - assets: VideoAssets to create AVMutableVideoCompositionLayerInstruction from.
         - composition: AVMutableComposition to add the VideoAssets to.
         - widthMultiplier: Multiplier to scale the width of the video asset to the final VideoExport Size
         - heightMultiplier: Multiplier to scale the height of the video asset to the final VideoExport Size

     - Returns: An array of AVMutableVideoCompositionLayerInstruction's to be set as the layerInstructions for the AVMutableVideoCompositionInstruction before exporting the video.
     */
    private static func add(assets: [VideoAsset],
                            to composition: AVMutableComposition,
                            widthMultiplier: CGFloat,
                            heightMultiplier: CGFloat) -> [AVMutableVideoCompositionLayerInstruction] {
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

extension VideoExportManager {
    public static func exportVideoTest(with audio: [VideoAsset],
                                         canvasViewFrame: CGRect,
                                         finalExportSize: VideoExportSizes,
                                         viewToAdd: UIView,
                                         progress: @escaping (Float) -> (),
                                         success: @escaping () -> (),
                                         failure: @escaping (Error) -> ()) {
        let exportVideoSize = finalExportSize.rawValue

        // Canvas view has to be same aspect ratio as export video size
        guard canvasViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Seleected export size's aspect ratio does not equal Cropped View Frame's aspect ratio")
            return
        }

        // Multipliers to scale height and width to final export size
        let heightMultiplier: CGFloat = exportVideoSize.height / canvasViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / canvasViewFrame.width

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        //// Create video tracks ////
        let mainInstruction = AVMutableVideoCompositionInstruction()

        var totalVideoDuration = kCMTimeZero
        totalVideoDuration = audio[0].timeRange.duration

        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalVideoDuration)

        // 2 - Add all asset tracks to mixComposition
        // 3 - Get instructions for all assets
        let instructions = self.add(assets: [audio[1]], to: mixComposition, widthMultiplier: widthMultiplier, heightMultiplier: heightMultiplier)

        // 4 - Add instructions to mainInstruction
        mainInstruction.layerInstructions = instructions
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        // @TODO: Add framerate
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = exportVideoSize

        //@TODO: Clean this up
        /*
         MARK: Parent Layer
         This layer is for adding all of our CALayers that will go over the video layer
         */
//        let parentlayer = CALayer()
//        parentlayer.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
//        parentlayer.isGeometryFlipped = true
//        parentlayer.addSublayer(videolayer)

//        let label = UILabel(text: "TESTINGTESTINGTESTINGTESTINGTESTING")
//        label.font = UIFont.boldSystemFont(ofSize: 40)
//        label.frame = CGRect(x: 0, y: 0, width: 700, height: 200)
//        label.textColor = .red
//        label.backgroundColor = .yellow
//        label.layer.display()
//
//        let view = UIView()
//        view.frame = CGRect(x: 50, y: 50, width: 200, height: 200)
//        view.backgroundColor = .yellow
//
//        let layer = CALayer()
//        layer.backgroundColor = UIColor.red.cgColor
//        layer.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
//
//        parentlayer.addSublayer(label.layer)
//        parentlayer.addSublayer(view.layer)

        // Scale adding view
        let xScale = exportVideoSize.width / viewToAdd.frame.size.width
        let yScale = exportVideoSize.height / viewToAdd.frame.size.height
        viewToAdd.scale(by: CGPoint(x: xScale, y: yScale))
//        viewToAdd.layer.isGeometryFlipped = true
        viewToAdd.frame.origin = .zero
//        viewToAdd.frame.origin = CGPoint(x: 0, y:0)
//        viewToAdd.frame.origin = CGPoint(x: 0, y: 0)

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: exportVideoSize)

        let parentlayer = viewToAdd.layer
//        parentlayer.frame = CGRect(origin: .zero, size: exportVideoSize)
        parentlayer.isGeometryFlipped = true
//        viewToAdd.layer.changePositionX(to: 100, beginTime: 0, duration: 12)
//        parentlayer.addSublayer(videoLayer)
//        parentlayer.addSublayer(viewToAdd.layer)

//        var fadeAnimation = CABasicAnimation(keyPath: "opacity")
//        fadeAnimation.fromValue = 1.0
//        fadeAnimation.toValue = 0.0
//        fadeAnimation.isAdditive = false
//        fadeAnimation.isRemovedOnCompletion = false
//        fadeAnimation.beginTime = 2.0
//        fadeAnimation.duration = 2.0
//        fadeAnimation.fillMode = kCAFillModeBoth
//        parentlayer.add(fadeAnimation, forKey: nil)

        /*
         MARK: Animation Sync Layer
         */
        let avSynchronizedLayer = AVSynchronizedLayer()
        // Add parent layer to contents
        avSynchronizedLayer.contents = parentlayer
        avSynchronizedLayer.frame = CGRect(origin: .zero, size: exportVideoSize)
        avSynchronizedLayer.masksToBounds = true

        // Add avSynchronizedLayer to Parent Layer
        parentlayer.addSublayer(avSynchronizedLayer)

        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: parentlayer, in: parentlayer)

        // @TODO: Add audio tracks
        // - Audio track
        let loadedAudioAsset = audio[0].urlAsset
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(audio[0].timeRange,
                                            of: loadedAudioAsset.tracks(withMediaType: .audio).first!,
                                            at: kCMTimeZero)
        } catch _ {
            print("Failed to load audio track")
        }

        // - Export
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition, avMutatableVideoComposition: avMutableVideoComposition, progress: progress, success: success, failure: failure)
    }
}
