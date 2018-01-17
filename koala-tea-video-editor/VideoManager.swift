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
}

public class VideoManager {
    public class func createAnimationLayer(completion: @escaping () -> ()) {
        ////////////////////////////
        //MARK: Video Track Getter//
        ////////////////////////////
        
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let asset = AVAsset(url: videoURL)
        
        let avMutableComposition = AVMutableComposition()
        
        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = track.first! as AVAssetTrack
        let timerange = CMTimeRangeMake(kCMTimeZero, asset.duration)

        let reader = try! AVAssetReader(asset: asset)

        _ = asset.tracks(withMediaType: AVMediaType.video)[0]

        // read video frames as BGRA
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        reader.add(trackReaderOutput)
        reader.startReading()

        var i = 0
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                let image = VideoManager.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                print(image, "\(i)")
                i += 1
        }
        
        let compositionVideoTrack:AVMutableCompositionTrack = avMutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: kCMTimeZero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        let size = videoTrack.naturalSize
        
        /////////////////////
        //MARK: Video Layer//
        /////////////////////
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        //////////////////////
        //MARK: Parent Layer//
        //////////////////////
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)

        ///////////////////////
        //MARK: CALayerToAdd//
        //////////////////////
        _ = "positionXAnimation"
        
        // Text
        //
        
        let textLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: 0, width: 1280, height: 173),
                                                         text: "NO",
                                                         textColor: .white,
                                                         font: UIFont.systemFont(ofSize: 124, weight: .bold))
        
        let longNoLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 1280, y: 0, width: 1280 * 2, height: 173),
                                                           text: "NO" + String(repeating: "O", count: 200),
                                                           textColor: .white,
                                                           font: UIFont.systemFont(ofSize: 124, weight: .bold))
        
        let godLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: 0, width: 1280, height: 173),
                                                        text: "GOD",
                                                        textColor: .white,
                                                        font: UIFont.systemFont(ofSize: 124, weight: .bold))
        
        let pleaseLayer = CoreLayerManager.createTextLayer(frame: CGRect(x: 0, y: 0, width: 1280, height: 173),
                                                           text: "PLEASE",
                                                           textColor: .white,
                                                           font: UIFont.systemFont(ofSize: 124, weight: .bold))
        
        // @TODO: guard get first track
        // Also figure out variable framerate checking
        let frameRate = asset.tracks.first!.nominalFrameRate
        
        // 30 = framerate
        let timePerFrame: Double = Double(1.0 / frameRate)
        
        textLayer.hideLayer(at: -1.0)
        textLayer.showLayer(at: timePerFrame * 18, till: timePerFrame * 35)
        textLayer.showLayer(at: timePerFrame * 107, till: timePerFrame * 114)
        textLayer.showLayer(at: timePerFrame * 151, till: timePerFrame * 162)
        textLayer.showLayer(at: timePerFrame * 169, till: timePerFrame * 180)
        textLayer.showLayer(at: timePerFrame * 206, till: timePerFrame * 218)
        
        godLayer.hideLayer(at: -1.0)
        godLayer.showLayer(at: timePerFrame * 42, till: timePerFrame * 56)
        godLayer.showLayer(at: timePerFrame * 124, till: timePerFrame * 130)
        
        pleaseLayer.hideLayer(at: -1.0)
        pleaseLayer.showLayer(at: timePerFrame * 136, till: timePerFrame * 146)
        
        longNoLayer.hideLayer(at: -1.0)
        longNoLayer.showLayer(at: timePerFrame * 258, till: timePerFrame * 285)
        let duration = (timePerFrame * 300) - (timePerFrame * 258)
        longNoLayer.changePositionX(to: -300, beginTime: timePerFrame * 258, duration: duration)
        longNoLayer.hideLayer(at: timePerFrame * 285)
        
        // Add CALayerToAdd to Parent Layer
        parentlayer.addSublayer(textLayer)
        parentlayer.addSublayer(godLayer)
        parentlayer.addSublayer(pleaseLayer)
        parentlayer.addSublayer(longNoLayer)
        
        ////////////////////////////////
        //MARK: Animation Layout Layer//
        ////////////////////////////////
        
        let avSynchronizedLayer = AVSynchronizedLayer()
        // Add parent layer to contents
        avSynchronizedLayer.contents = parentlayer
        
        // Add the animation from CALayerToAdd
        let keys = textLayer.animationKeys() ?? []
        
        for key in keys {
            let anim = textLayer.animation(forKey: key)
            avSynchronizedLayer.add(anim!, forKey: key)
        }
        
        avSynchronizedLayer.frame = parentlayer.frame
        avSynchronizedLayer.masksToBounds = true
        
        // Add avSynchronizedLayer to Parent Layer
        parentlayer.addSublayer(avSynchronizedLayer)
        
        /////////////////////
        //MARK: Composition//
        /////////////////////
        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        avMutableVideoComposition.renderSize = CGSize(width: size.width, height: size.height)
        avMutableVideoComposition.renderScale = 1.0
        avMutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avMutableComposition.duration)
        
        let videotrack = avMutableComposition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        
        layerinstruction.setTransform(videoTrack.preferredTransform, at: kCMTimeZero)
        
        instruction.layerInstructions = [layerinstruction]
        avMutableVideoComposition.instructions = [instruction]
        
        // Export
        
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
        
        guard let assetExport = AVAssetExportSession(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality) else {return}
        assetExport.videoComposition = avMutatableVideoComposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = fileURL
        
        // Schedule timer for sending progress
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                progress(assetExport.progress)
                if assetExport.progress == 1.0 {
                    timer.invalidate()
                }
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
                break
            case .exporting:
                print("exporting")
                break
            case .waiting:
                print("waiting")
                break
            case .cancelled:
                print("cancelled")
                failure(VideoManagerError.CancelledError)
                break
            case .failed:
                print("failed: \(assetExport.error!)")
                failure(VideoManagerError.FailedError)
                break
            case .unknown:
                print("unknown")
                failure(VideoManagerError.UnknownError)
                break
            }
        })
    }


    // Lightning fast CMSampleBuffer to UIImage
    static func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage {
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
}
