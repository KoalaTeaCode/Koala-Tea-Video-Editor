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
        
        VideoHelpers.createAnimationLayer {
            expectation.fulfill()
        }
        
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 240.0)
    }
}
