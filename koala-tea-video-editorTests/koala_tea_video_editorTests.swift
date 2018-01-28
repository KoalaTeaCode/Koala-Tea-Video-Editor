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

        let currentMediaTime = CACurrentMediaTime()
        let videoURL: URL = Bundle.main.url(forResource: "outputfile", withExtension: "mp4")!


        let vid1 = VideoAsset(assetName: "test", url: videoURL, frame: CGRect(x: 0, y: 0, width: 640, height: 360))
        let vid2 = VideoAsset(assetName: "test", url: videoURL, frame: CGRect(x: vid1.frame.maxX, y: vid1.frame.maxY, width: 640, height: 360))
        VideoManager.exportMergedVideo(with: [vid1,vid2], croppedViewFrame: CGRect(x: 0, y: 0, width: 1280, height: 720))

//        VideoManager.exportVideo(from: vid1.urlAsset, avPlayerFrame: CGRect(x: 0, y: 0, width: 375, height: 375/(16/9)), croppedViewFrame: CGRect(x: 0, y: 0, width: 300, height: 300), caLayers: [], currentMediaTimeUsed: currentMediaTime)

        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 40.0)
    }
}
