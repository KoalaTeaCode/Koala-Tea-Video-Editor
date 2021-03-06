//
//  koala_tea_video_editorTests.swift
//  koala-tea-video-editorTests
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import XCTest
import AVFoundation
import CoreImage
@testable import koala_tea_video_editor

class koala_tea_video_editorTests: XCTestCase {
    
//    var videoWriter: VideoWriter? = nil
    let filename = "testing.mp4"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let expectation = XCTestExpectation(description: "create video")

//        let currentMediaTime = CACurrentMediaTime()
//        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!
//        let videoURL2: URL = Bundle.main.url(forResource: "vertical", withExtension: "mp4")!
//
//        let frame = CGRect(x: 0, y: 0, width: 720, height: 720)
//        let vid1 = VideoAsset(assetName: "vert", url: videoURL2, frame: CGRect(origin: CGPoint(x: frame.midX - 200, y: frame.midY - 200), size: CanvasFrameSizes._9x16(forSize: CGSize(width: 720, height: 720)).rawValue))
//        vid1.setStartime(to: 0.0)
//        vid1.setEndTime(to: 6.0)
//
//        let vid2 = VideoAsset(assetName: "test", url: videoURL, frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CanvasFrameSizes._16x9(forSize: CGSize(width: 720, height: 720)).rawValue))
//        vid2.setStartime(to: 0.0)
//        vid2.setEndTime(to: 6.0)
//
//        let vid3 = VideoAsset(assetName: "vert", url: videoURL2, frame: CGRect(origin: CGPoint(x: frame.midX - 200, y: frame.midY - 200), size: CanvasFrameSizes._9x16(forSize: CGSize(width: 720, height: 720)).rawValue))
//        vid3.setStartime(to: 0.0)
//        vid3.setEndTime(to: 6.0)

//        VideoExportManager.exportMergedVideo(with: [vid1, vid2, vid3], canvasViewFrame: frame, finalExportSize: ._1080x1080)


//        VideoManager.exportVideo(from: vid1.urlAsset, avPlayerFrame: CGRect(x: 0, y: 0, width: 375, height: 375/(16/9)), croppedViewFrame: CGRect(x: 0, y: 0, width: 300, height: 300), caLayers: [], currentMediaTimeUsed: currentMediaTime)

//        self.measure {
        let fileURL: URL = Bundle.main.url(forResource: "podcast", withExtension: "mp3")!
        let audioAsset = AVURLAsset(url: fileURL)
        let audioDuration = audioAsset.duration.seconds

        // Greater samples per second for accuracy
        let samplesPerSecond = 1000.0
        let sampleCount = samplesPerSecond * audioDuration

        let start = CACurrentMediaTime()
        let samples = AudioProcessor.waveformSamples(from: audioAsset, count: Int(sampleCount))
        print(CACurrentMediaTime() - start)

        // Seperate duration into parts then in array
        // Create audioprocessor async for each part
        // Dispatch group for all parts
        // When finished join all parts
        // then complete

//        let _ = AudioProcessor.waveformSamples(from: audioAsset, count: Int(sampleCount), startTimeInSeconds: (60 * 10) * 2, durationInSeconds: 60 * 10)

//        }
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 30.0)
    }
}
