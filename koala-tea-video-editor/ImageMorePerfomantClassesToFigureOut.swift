//
//  ImageMorePerfomantClassesToFigureOut.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/15/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

// Example
class t {
    func t() {
//        let reader = try! AVAssetReader(asset: avAsset)
//
//        // read video frames as BGRA
//        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
//                                                         outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
//        reader.add(trackReaderOutput)
//        reader.startReading()
//
//        var i = 0
//        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
//            let image = VideoManager.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
//            images.append(image)
//            //            print(image, "\(i)")
//            i += 1
//        }
//
//        self.imageView = UIImageView()
//        imageView.frame = self.view.frame
//        imageView.frame.size.height = imageView.frame.width / (16/9)
//        imageView.backgroundColor = .red
//        imageView.contentMode = .scaleAspectFit
//        self.view.addSubview(imageView)

//        var i2 = 0
//        if #available(iOS 10.0, *) {
//            Timer.scheduledTimer(withTimeInterval: TimeInterval(1/30.0), repeats: true, block: { (timer) in
//                guard i2 < self.images.count else {
//                    i2 = 0
//                    return
//                }
//                imageView.image = self.images[i2]
//                i2 += 1
//            })
//        } else {
//            // Fallback on earlier versions
//        }

//        var theseImage = [UIImage]()
//        for i in 0..<images.count {
//            let backImage = images[i]
//            let newi = ImageAnimator.createNewImage(backgroudImage: backImage, overLayer: textLayer, imageView: imageView)
//            theseImage.append(newi)
//        }

//        var i2 = 0
//        Timer.scheduledTimer(withTimeInterval: TimeInterval(1/asset.tracks.first!.nominalFrameRate), repeats: true, block: { (timer) in
//            guard i2 < self.images.count else {
//                i2 = 0
//                return
//            }
//            imageView.image = theseImage[i2]
//            i2 += 1
//        })

//        let settings = RenderSettings(size: CGSize(width:1280, height:720), fps: 30, avCodecKey: AVVideoCodecType.h264, videoFilename: "test", videoFilenameExt: "mp4")
//        print(settings.outputURL)
//        let imageAnimator = ImageAnimator(renderSettings: settings)
//        imageAnimator.images = theseImage
//        imageAnimator.render() {
//            print("image animator rendered")
//        }
    }
}

class RenderSettings {

    var size : CGSize = .zero
    var fps: Int32 = 6   // frames per second
    var avCodecKey: AVVideoCodecType
    var videoFilename = "render"
    var videoFilenameExt = "mp4"

    init(avCodecKey: AVVideoCodecType) {
        self.avCodecKey = avCodecKey
    }

    var outputURL: URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        }
        fatalError("URLForDirectory() failed")
    }
}


class ImageAnimator {
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600

    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images: [UIImage]!

    var frameNum = 0

    class func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", error)
                }
            }
        }
    }

    class func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }

    init(renderSettings: RenderSettings) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
        //        images = loadImages()
    }

    func render(completion: (()->Void)?) {

        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)

        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            ImageAnimator.saveToLibrary(videoURL: self.settings.outputURL)
            completion?()
        }

    }

    //    // Replace this logic with your own.
    //    func loadImages() -> [UIImage] {
    //        var images = [UIImage]()
    //        for index in 1...10 {
    //            let filename = "\(index).jpg"
    //            images.append(UIImage(named: filename)!)
    //        }
    //        return images
    //    }

    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: VideoWriter) -> Bool {

        let frameDuration = CMTimeMake(Int64(ImageAnimator.kTimescale / settings.fps), ImageAnimator.kTimescale)

        while !images.isEmpty {

            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }

            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, Int32(frameNum))
            let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }

            frameNum += 1
        }

        // Inform writer all buffers have been written.
        return true
    }

    // Create new image with image2 on top of image 1
    class func createNewImage(backgroudImage: UIImage, overlayImage: UIImage, imageView: UIImageView) -> UIImage {
        let bottomImage = backgroudImage
        let topImage = overlayImage

        //        let multiplier = 768.0 / 375.0
        let multiplier = 1.0
        let size = backgroudImage.size
        UIGraphicsBeginImageContext(size)

        let firstImageSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: firstImageSize)

        let angle = atan2f(Float(imageView.transform.b), Float(imageView.transform.a))

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Have to use center of imageView

        let centerX = imageView.center.x * CGFloat(multiplier)
        let centerY = imageView.center.y * CGFloat(multiplier)

        // Get scale of transform of imageView
        let transform = imageView.transform
        let xScale = sqrt(transform.a * transform.a + transform.c * transform.c)
        let yScale = sqrt(transform.b * transform.b + transform.d * transform.d)

        // Multiply bounds width by scale
        // Bounds width is the original image view size
        let width = imageView.bounds.width * xScale
        let height = imageView.bounds.height * yScale

        let this = CGRect(x: centerX, y: centerY, width: width * CGFloat(multiplier), height: height * CGFloat(multiplier))
        return newImage.putImage(image: topImage, on: this, angle: CGFloat(angle))
    }

    // Create new image with image2 on top of image 1
    class func createNewImage(backgroudImage: UIImage, overLayer: CALayer, imageView: UIImageView) -> UIImage {
        let bottomImage = backgroudImage
        //        let topImage = overlayImage

        print(overLayer.frame)

        //        print(overlayImage.size)
        //        let multiplier = 768.0 / 375.0
        let multiplier = 1.0
        //        let size = CGSize(width: 375 * multiplier, height: 375 * multiplier)
        let size = CGSize(width: 1280, height: 720)
        UIGraphicsBeginImageContext(size)

        let firstImageSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: firstImageSize)

        _ = atan2f(Float(imageView.transform.b), Float(imageView.transform.a))

        UIGraphicsGetCurrentContext()!.translateBy(x: 0, y: 720 - 160)
        overLayer.draw(in: UIGraphicsGetCurrentContext()!)

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Have to use center of imageView

        let centerX = imageView.center.x * CGFloat(multiplier)
        let centerY = imageView.center.y * CGFloat(multiplier)

        // Get scale of transform of imageView
        let transform = imageView.transform
        let xScale = sqrt(transform.a * transform.a + transform.c * transform.c)
        let yScale = sqrt(transform.b * transform.b + transform.d * transform.d)

        // Multiply bounds width by scale
        // Bounds width is the original image view size
        let width = 1280 * xScale
        let height = 720 * yScale

        _ = CGRect(x: centerX, y: centerY, width: width * CGFloat(multiplier), height: height * CGFloat(multiplier))
        //        return newImage.putImage(image: topImage, on: this, angle: CGFloat(angle))
        return newImage
    }
}


class VideoWriter {

    let renderSettings: RenderSettings

    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }

    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {

        var pixelBufferOut: CVPixelBuffer?

        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }

        let pixelBuffer = pixelBufferOut!

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))

        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit

        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0

        context?.draw(image.cgImage!, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }

    func start() {

        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: renderSettings.avCodecKey,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.size.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.size.height))
        ]

        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.size.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.size.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }

        func createAssetWriter(outputURL: URL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }

            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }

            return assetWriter
        }

        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }

        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()

        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }

        videoWriter.startSession(atSourceTime: kCMTimeZero)

        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }

    func render(appendPixelBuffers: ((VideoWriter)->Bool)?, completion: (()->Void)?) {

        precondition(videoWriter != nil, "Call start() to initialze the writer")

        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers?(self) ?? false
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
            else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }

    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {

        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")

        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}
