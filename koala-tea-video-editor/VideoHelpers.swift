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

fileprivate enum VideoHelpersError: Error {
    case FailedError
    case CancelledError
    case UnknownError
}

public class VideoHelpers {
    public class func createAnimationLayer(completion: @escaping () -> ()) {
        ////////////////////////////
        //MARK: Video Track Getter//
        ////////////////////////////
        
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
        let asset = AVAsset(url: videoURL)
        
        let avMutableComposition = AVMutableComposition()
        
        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack:AVAssetTrack = track[0] as AVAssetTrack
        let timerange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        
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
        let key = "positionXAnimation"
        
        // Colors
        //
        let bordercolor = UIColor(red: 0.795254, green: 0.795254, blue: 0.795254, alpha: 1)
        let foregroundcolor = UIColor.white
        
        // Fonts
        //
        let systemFontRegularFont = UIFont.systemFont(ofSize: 100.0, weight: UIFont.Weight.regular)
        
        // Text
        //
        let textLayer = CATextLayer()
        textLayer.name = "Text"
        textLayer.bounds = CGRect(x: 0, y: 0, width: 336, height: 138)
        textLayer.position = CGPoint(x: -168, y: 50)
        textLayer.contentsGravity = kCAGravityCenter
        textLayer.contentsScale = 2
        textLayer.borderWidth = 0
        textLayer.borderColor = bordercolor.cgColor
        textLayer.shadowOffset = CGSize(width: 0, height: 1)
        textLayer.magnificationFilter = kCAFilterNearest
        textLayer.needsDisplayOnBoundsChange = true
        textLayer.fillMode = kCAFillModeForwards
        
        // Text Animations
        //
        
        // position.x
        //
        let positionXAnimation = CABasicAnimation()
        positionXAnimation.beginTime = 0.6
        positionXAnimation.duration = 0.27918
        positionXAnimation.fillMode = kCAFillModeForwards
        positionXAnimation.isRemovedOnCompletion = false
//        positionXAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        positionXAnimation.keyPath = "position.x"
        positionXAnimation.toValue = 640
        
        textLayer.add(positionXAnimation, forKey: key)
        textLayer.string = "NO"
        textLayer.fontSize = 100
        textLayer.foregroundColor = foregroundcolor.cgColor
        textLayer.font = systemFontRegularFont
        textLayer.isWrapped = true
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.display()
        
        // Add CALayerToAdd to Parent Layer
        parentlayer.addSublayer(textLayer)
        
        ////////////////////////////////
        //MARK: Animation Layout Layer//
        ////////////////////////////////
        
        let avSynchronizedLayer = AVSynchronizedLayer()
        // Add parent layer to contents
        avSynchronizedLayer.contents = parentlayer
        
        // Add the animation from CALayerToAdd
        avSynchronizedLayer.add(textLayer.animation(forKey: key)!, forKey: key)
        
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
        
        VideoHelpers.exportVideo(avMutableComposition: avMutableComposition,
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
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { (timer) in
            progress(assetExport.progress)
            if assetExport.progress == 1.0 {
                timer.invalidate()
            }
        })
        
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
                failure(VideoHelpersError.CancelledError)
                break
            case .failed:
                print("failed: \(assetExport.error!)")
                failure(VideoHelpersError.FailedError)
                break
            case .unknown:
                print("unknown")
                failure(VideoHelpersError.UnknownError)
                break
            }
        })
    }
}
