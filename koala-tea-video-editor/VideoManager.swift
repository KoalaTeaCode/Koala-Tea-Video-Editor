//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

fileprivate enum VideoManagerError: Error {
    case FailedError
    case CancelledError
    case UnknownError
    case NoFirstVideoTrack
}

public class TimePoints {
    public var startTime: CMTime
    public var endTime: CMTime

    init(startTime: CMTime, endTime: CMTime) {
        self.startTime = startTime
        self.endTime = endTime
    }
}

extension TimePoints: Equatable {
    public static func ==(lhs: TimePoints, rhs: TimePoints) -> Bool {
        return lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime
    }
}

public class VideoAsset {
    // MARK: Types
    static let nameKey = "AssetName"

    // MARK: Properties

    /// The name of the asset to present in the application.
    public var assetName: String = ""

    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    public var urlAsset: AVURLAsset

    public var timePoints: TimePoints

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(timePoints.startTime, duration)
    }

    public var frame: CGRect


    public init(assetName: String, url: URL, frame: CGRect = CGRect.zero) {
        self.assetName = assetName
        let avURLAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.urlAsset = avURLAsset

        let timePoints = TimePoints(startTime: kCMTimeZero, endTime: self.urlAsset.duration)
        self.timePoints = timePoints

        self.frame = frame
    }

    // @TODO: What is a good timescale to use? Does the timescale need to depend on framerate?
    public func setStartime(to time: Double) {
        let cmTime = CMTimeMakeWithSeconds(time, 600)
        self.timePoints.startTime = cmTime
    }

    public func setEndTime(to time: Double) {
        let cmTime = CMTimeMakeWithSeconds(time, 600)

        if cmTime > self.urlAsset.duration {
            self.timePoints.endTime = self.urlAsset.duration
            return
        }

        self.timePoints.endTime = cmTime
    }
}

extension VideoAsset: Equatable {
    public static func == (lhs: VideoAsset, rhs: VideoAsset) -> Bool {
        return lhs.assetName == rhs.assetName &&
            lhs.urlAsset == lhs.urlAsset &&
            lhs.timePoints == rhs.timePoints
    }
}

enum FinalExportSizes {
    case _1080x1080
    case _1280x720
    case _720x1280
    case _1920x1080
    case _1080x1920
}

extension FinalExportSizes {
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
    public class func exportVideo(from asset: AVAsset, avPlayerFrame: CGRect, croppedViewFrame: CGRect, caLayers: [CALayer], currentMediaTimeUsed: Double) {
        guard let avMutableComposition = VideoManager.createAVMutableComposition(from: asset) else {
            return
        }

        guard let firstTrack = VideoManager.getFirstVideoTrack(from: asset) else {
            return
        }

        let inputVideoSize = firstTrack.naturalSize

        let exportVideoSize = CGSize(width: 1080, height: 1080)

        let heightMultiplier: CGFloat = exportVideoSize.height / croppedViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / croppedViewFrame.width

        let layerHeight = croppedViewFrame.height * heightMultiplier
        let layerWidth = croppedViewFrame.width * widthMultiplier
        let exportedLayerSize = CGSize(width: layerWidth, height: layerHeight)

        /*
         MARK: Parent Layer
         This layer is for adding all of our CALayers that will go over the video layer
         */
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: exportedLayerSize.width, height: exportedLayerSize.height)
        parentlayer.isGeometryFlipped = true

        /*
         MARK: Add CALayers To Parent View
         */
        // @TODO: Make this a completion handler
        // sometimes this gets skipped over
        let scaledLayers = VideoManager.getScaledLayers(for: caLayers, widthMultiplier: widthMultiplier, heightMultiplier: heightMultiplier, currentMediaTimeUsed: currentMediaTimeUsed)
        for layer in scaledLayers {
            parentlayer.addSublayer(layer)
        }

        /*
         MARK: Animation Sync Layer
         */
        let avSynchronizedLayer = AVSynchronizedLayer()
        avSynchronizedLayer.contents = parentlayer
        avSynchronizedLayer.frame = parentlayer.frame
        avSynchronizedLayer.masksToBounds = true
        parentlayer.addSublayer(avSynchronizedLayer)

        /*
         MARK: Video Composition
         */
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = CGSize(width: exportVideoSize.width, height: exportVideoSize.height)
        avMutableVideoComposition.renderScale = 1.0
        //@TODO: Can we not have videoLayer??
        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: parentlayer, in: parentlayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avMutableComposition.duration)

        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)


        //@TODO: Make this work in comparison to input avlayer
        // This is the transform for the AVMutableVideoComposition i.e. Video Layer

        let scaledX: CGFloat = avPlayerFrame.minX * widthMultiplier
        let scaledY: CGFloat = avPlayerFrame.minY * heightMultiplier

        let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: inputVideoSize.width, height: inputVideoSize.height),
                                          toRect: CGRect(x: scaledX, y: scaledY, width: avPlayerFrame.width * widthMultiplier, height: avPlayerFrame.height * heightMultiplier))
        layerinstruction.setTransform(transform, at: kCMTimeZero)
//        layerinstruction.setTransform(firstTrack.preferredTransform, at: kCMTimeZero)

        instruction.layerInstructions = [layerinstruction]
        avMutableVideoComposition.instructions = [instruction]

        /*
         MARK: Video Exporter
         */
        VideoManager.exportVideo(avMutableComposition: avMutableComposition,
                                 avMutatableVideoComposition: avMutableVideoComposition,
                                 progress: { (progress) in
            print(progress)
        }, success: {
//            completion()
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    public class func exportVideo(from assets: [VideoAsset], avPlayerFrame: CGRect, croppedViewFrame: CGRect, caLayers: [CALayer], currentMediaTimeUsed: Double) {
        VideoManager.createAVMutableComposition(from: assets) { (avMutableComposition) in
            guard let avMutableComposition = avMutableComposition else {
                assertionFailure("avMutableComposition == nil bruh")
                return
            }
            guard let firstTrack = VideoManager.getFirstVideoTrack(from: assets.first!.urlAsset) else {
                return
            }

            let inputVideoSize = firstTrack.naturalSize

            let exportVideoSize = CGSize(width: 1080, height: 1080)

            let heightMultiplier: CGFloat = exportVideoSize.height / croppedViewFrame.height
            let widthMultiplier: CGFloat = exportVideoSize.width / croppedViewFrame.width

            let layerHeight = croppedViewFrame.height * heightMultiplier
            let layerWidth = croppedViewFrame.width * widthMultiplier
            let exportedLayerSize = CGSize(width: layerWidth, height: layerHeight)

            /*
             MARK: Parent Layer
             This layer is for adding all of our CALayers that will go over the video layer
             */
            let parentlayer = CALayer()
            parentlayer.frame = CGRect(x: 0, y: 0, width: exportedLayerSize.width, height: exportedLayerSize.height)
            parentlayer.isGeometryFlipped = true

            /*
             MARK: Add CALayers To Parent View
             */
            // @TODO: Make this a completion handler
            // sometimes this gets skipped over
            let scaledLayers = VideoManager.getScaledLayers(for: caLayers, widthMultiplier: widthMultiplier, heightMultiplier: heightMultiplier, currentMediaTimeUsed: currentMediaTimeUsed)
            for layer in scaledLayers {
                parentlayer.addSublayer(layer)
            }

            /*
             MARK: Animation Sync Layer
             */
            let avSynchronizedLayer = AVSynchronizedLayer()
            avSynchronizedLayer.contents = parentlayer
            avSynchronizedLayer.frame = parentlayer.frame
            avSynchronizedLayer.masksToBounds = true
            parentlayer.addSublayer(avSynchronizedLayer)

            /*
             MARK: Video Composition
             */
            let avMutableVideoComposition = AVMutableVideoComposition()
            avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
            avMutableVideoComposition.renderSize = CGSize(width: exportVideoSize.width, height: exportVideoSize.height)
            avMutableVideoComposition.renderScale = 1.0
            //@TODO: Can we not have videoLayer??
            avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: parentlayer, in: parentlayer)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avMutableComposition.duration)

            let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)


            //@TODO: Make this work in comparison to input avlayer
            // This is the transform for the AVMutableVideoComposition i.e. Video Layer

            let scaledX: CGFloat = avPlayerFrame.minX * widthMultiplier
            let scaledY: CGFloat = avPlayerFrame.minY * heightMultiplier

            let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: inputVideoSize.width, height: inputVideoSize.height),
                                              toRect: CGRect(x: scaledX, y: scaledY, width: avPlayerFrame.width * widthMultiplier, height: avPlayerFrame.height * heightMultiplier))
            layerinstruction.setTransform(transform, at: kCMTimeZero)
            //        layerinstruction.setTransform(firstTrack.preferredTransform, at: kCMTimeZero)

            instruction.layerInstructions = [layerinstruction]
            avMutableVideoComposition.instructions = [instruction]

            /*
             MARK: Video Exporter
             */
            VideoManager.exportVideo(avMutableComposition: avMutableComposition,
                                     avMutatableVideoComposition: avMutableVideoComposition,
                                     progress: { (progress) in
                print(progress)
            }, success: {
                //            completion()
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }

    private class func createAVMutableComposition(from assets: [VideoAsset], completion: @escaping (_ avMutableComposition: AVMutableComposition?) -> ()) {
        let avMutableComposition = AVMutableComposition()

        let dispatchGroup = DispatchGroup()
        // @TODO: Add completion for this?
        for videoAsset in assets {
            dispatchGroup.enter()
            guard let index = assets.index(of: videoAsset) else {
                continue
            }

            guard let videoTrack = VideoManager.getFirstVideoTrack(from: videoAsset.urlAsset) else {
                completion(nil)
                continue
            }
            let timerange = videoAsset.timeRange

            let compositionVideoTrack: AVMutableCompositionTrack = avMutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!

            var atTime = kCMTimeZero
            if index != 0 {
                guard let previousTrack = assets.item(at: index - 1) else {
                    assertionFailure("previous track issue")
                    continue
                }
                atTime = previousTrack.timePoints.endTime
            }

            do {
                try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: atTime)
                compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
                dispatchGroup.leave()
            } catch {
                assertionFailure(error.localizedDescription)
                completion(nil)
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(avMutableComposition)
        }
    }

    private class func createAVMutableComposition(from asset: AVAsset) -> AVMutableComposition? {
        let avMutableComposition = AVMutableComposition()

        guard let videoTrack = VideoManager.getFirstVideoTrack(from: asset) else {
            return nil
        }
        let timerange = CMTimeRangeMake(kCMTimeZero, asset.duration)

        let compositionVideoTrack: AVMutableCompositionTrack = avMutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!

        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: kCMTimeZero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
            return avMutableComposition
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }

    private class func getFirstVideoTrack(from asset: AVAsset) -> AVAssetTrack? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else {
            assertionFailure("Failure getting first track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }

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
        VideoManager.exportVideo(avMutableComposition: avMutableComposition,
                                 avMutatableVideoComposition: avMutableVideoComposition,
        progress: { (progress) in
            print(progress)
        }, success: {
            completion()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    public static func exportVideo(avMutableComposition: AVMutableComposition,
                                   avMutatableVideoComposition: AVMutableVideoComposition,
                                   progress: @escaping (Float) -> (),
                                   success: @escaping () -> (),
                                   failure: @escaping (Error) -> ()) {
        //////////////////////
        //MARK: Export Video//
        //////////////////////
        guard let fileURL = FileHelpers.getDocumentsURL(for: "test", extension: "mp4") else {
            return
        }
        
        // Remove any file at URL
        // If file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)
        
        //////////////////////////////
        //MARK: AVAssetExportSession//
        //////////////////////////////
        
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
            //@TODO: Show status or pass it back in completion
            switch assetExport.status {
            case .completed:
                print("success")
                success()
                print(fileURL)

                timer?.invalidate()
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

                timer?.invalidate()
                break
            case .failed:
                assertionFailure("failed: \(assetExport.error!)")
                failure(VideoManagerError.FailedError)

                timer?.invalidate()
                break
            case .unknown:
                assertionFailure("unknown")
                failure(VideoManagerError.UnknownError)

                timer?.invalidate()
                break
            }
        })
    }


    // Lightning fast CMSampleBuffer to UIImage
    private static func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);

        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);

        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);

        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();

        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);

        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!);

        return (image);
    }

    static func getAllFramesAsUIImages(for asset: AVAsset) -> [UIImage]? {
        var images: [UIImage] = []

        // Frame Reader
        let reader = try! AVAssetReader(asset: asset)

        guard let firstTrack = VideoManager.getFirstVideoTrack(from: asset) else {
            return nil
        }

        // read video frames as BGRA
        let trackReaderOutput = AVAssetReaderTrackOutput(track: firstTrack,
                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        reader.add(trackReaderOutput)
        reader.startReading()

        var i = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
            let image = VideoManager.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            images.append(image)
            i += 1
        }

        // @TODO: need to end reading?

        return images
    }
}

extension CGSize {
    public func getAspectRatio() -> CGFloat {
        return self.height / self.width
    }
}

// Multiple assets
extension VideoManager {
    static func exportMergedVideo(with assets: [VideoAsset], croppedViewFrame: CGRect, finalExportSize: FinalExportSizes) {
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
        VideoManager.exportVideo(avMutableComposition: mixComposition,
                                 avMutatableVideoComposition: avMutableVideoComposition,
                                 progress: { (progress) in
            print(progress)
        }, success: {
//                completion()
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    static func add(assets: [VideoAsset], to composition: AVMutableComposition, widthMultiplier: CGFloat, heightMultiplier: CGFloat) -> [AVMutableVideoCompositionLayerInstruction] {
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

    static func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: VideoAsset, widthMultiplier: CGFloat, heightMultiplier: CGFloat) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.urlAsset.tracks(withMediaType: AVMediaType.video).first!

        // @TODO: Add in fixing rotation issue for portrait and .down videos
//        let transform = assetTrack.preferredTransform
//        let assetInfo = orientationFromTransform(transform: transform)

//        var scaleToFitRatio = size.width / assetTrack.naturalSize.width
//        if assetInfo.isPortrait {
//            scaleToFitRatio = size.width / assetTrack.naturalSize.height
//            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
//            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),
//                                     at: kCMTimeZero)
//        } else {
//            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            // @TODO: why do we need to transform?
//            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: 0))
//            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: size.width / 2))
//            if assetInfo.orientation == .down {
//                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(M_PI))
//                let windowBounds = size
//                let yFix = assetTrack.naturalSize.height + windowBounds.height
//                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
//                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
//            }
//            instruction.setTransform(concat, at: kCMTimeZero)
//        let heightMultiplier: CGFloat = exportVideoSize.height / croppedViewFrame.height
//        let widthMultiplier: CGFloat = exportVideoSize.width / croppedViewFrame.width

        let scaledX: CGFloat = asset.frame.minX * widthMultiplier
        let scaledY: CGFloat = asset.frame.minY * heightMultiplier
        let scaledWidth = asset.frame.width * widthMultiplier
        let scaledHeight = asset.frame.height * heightMultiplier

            let transform = CGAffineTransform(from: CGRect(x: 0, y: 0, width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height),
                                              toRect: CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight))
            instruction.setTransform(transform, at: kCMTimeZero)
//        }
        return instruction
    }

    static func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
}
