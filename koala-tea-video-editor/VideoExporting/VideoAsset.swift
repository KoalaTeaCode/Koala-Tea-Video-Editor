//
//  VideoAsset.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import KoalaTeaPlayer

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
