//
//  WaveformGenerator.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 4/24/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

class WaveformGenerator {
    static func generateFullWaveform(samples: [Float], totalWidth: CGFloat, height: CGFloat, singleWaveWidth: CGFloat, spacing: CGFloat) -> UIView {
        // @TODO: accept height
        let waveformView = UIView(frame: CGRect(x: 0, y: 0, width: totalWidth, height: height))

        let finalWaveCount = totalWidth.double / (singleWaveWidth.double + spacing.double)

        let clusterSize = samples.count.double / finalWaveCount

        let clusterSizeRounded = (clusterSize * 10.0).rounded() / 10.0
        let averageArray = self.clusterAndGetAverages(array: samples,
                                                      clusterSize: clusterSizeRounded,
                                                      totalDesiredCount: finalWaveCount)

        // @TODO: if final count + spacing is > desired size then adjust spacing accordingly
        for (index, sample) in averageArray.enumerated() {
            let multiplier: Float = height.float / 2
            
            var height = (sample * 2) * multiplier
            if height <= 0 {
                height = (0.005 * 2) * multiplier
            }

            let x = index.cgFloat * (singleWaveWidth + spacing)
            let view = UIView(frame: CGRect(x: x,
                                            y: waveformView.height / 2,
                                            width: singleWaveWidth,
                                            height: height.cgFloat))
            view.backgroundColor = .yellow
            view.cornerRadius = view.width / 2

            let topViewY = waveformView.height / 2 - view.height
            let topView = UIView(frame: view.frame)
            topView.y = topViewY
            topView.cornerRadius = view.cornerRadius
            topView.backgroundColor = view.backgroundColor

            view.isUserInteractionEnabled = false
            topView.isUserInteractionEnabled = false

            waveformView.addSubview(topView)
            waveformView.addSubview(view)
        }
        
        return waveformView
    }

    static func clusterAndGetAverages(array: [Float], clusterSize: Double, totalDesiredCount: Double) -> [Float] {
        return self.filterAndAverage(cluster: self.cluster(array: array, by: clusterSize, totalDesiredCount: totalDesiredCount))
    }

    static func cluster(array: [Float], by clusterSize: Double, totalDesiredCount: Double) -> [[Float]] {
        var currentClusterSize = clusterSize
        var clusters = [[Float]]()
        var currentCluster = [Float]()

        var counter: Double = 1

        for (item) in array {
            if (counter / currentClusterSize <= 1) {
                currentCluster.append(item)
                counter += 1

                if totalDesiredCount.int == clusters.count {
                    // At the last array
                    clusters.append(currentCluster)
                }

                continue
            }

            currentClusterSize += clusterSize
            counter += 1
            currentCluster.append(item)
            clusters.append(currentCluster)
            currentCluster = []
        }

        return clusters
    }

    static func filterAndAverage(cluster: [[Float]]) -> [Float] {
        var averages = [Float]()

        if cluster.count == 1 {
            return cluster.first!
        }

        for array in cluster {
            // Get average from array
            let average = array.average()

            // Add average to new array
            averages.append(average)
        }

        return averages
    }
}

//
// see
// * http://www.davidstarke.com/2015/04/waveforms.html
// * http://stackoverflow.com/questions/28626914
// for very good explanations of the asset reading and processing path
//

import Foundation
import Accelerate
import AVFoundation

class AudioProcessor {

    private static func assetReader(for audioAsset: AVURLAsset) -> AVAssetReader? {
        guard let assetReader = try? AVAssetReader(asset: audioAsset),
            let _ = audioAsset.tracks.first else {
                assertionFailure("Not first track")
                return nil
        }
        return assetReader
    }

    static func waveformSamples(from audioAsset: AVURLAsset, count: Int) -> [Float]? {
        guard let assetReader = self.assetReader(for: audioAsset) else {
            assertionFailure("No asset reader")
            return nil
        }
        guard let audioTrack = assetReader.asset.tracks.first else {
            return nil
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        let requiredNumberOfSamples = count
        let samples = extract(samplesFrom: assetReader, downsampledTo: requiredNumberOfSamples)

        switch assetReader.status {
        case .completed:
            return normalize(samples)
        default:
            print("ERROR: reading waveform audio data has failed \(assetReader.status)")
            return nil
        }
    }
}

// MARK: - Private

extension AudioProcessor {
    fileprivate static func getLevel(from decibels: Float) -> Float {
        var level: Float = 0.0
        // The linear 0.0 .. 1.0 value we need.
        let minDecibels: Float = -160.0

        if decibels < minDecibels {
            level = 0.0
        } else if decibels >= 0.0 {
            level = 1.0
        } else if decibels.ulp == minDecibels.ulp {
            level = 0.0
        } else {
            let root: Float = 2.0
            let minAmp: Float = powf(10.0, 0.05 * minDecibels)
            let inverseAmpRange: Float = 1.0 / (1.0 - minAmp)
            let amp: Float = powf(10.0, 0.05 * decibels)
            let adjAmp: Float = (amp - minAmp) * inverseAmpRange
            level = powf(adjAmp, 1.0 / root)
        }
        
        return level
    }
    private static var silenceDbThreshold: Float { return -160.0 } // everything below -50 dB will be clipped

    fileprivate static func extract(samplesFrom assetReader: AVAssetReader, downsampledTo targetSampleCount: Int) -> [Float] {
        var outputSamples = [Float]()

        assetReader.startReading()
        while assetReader.status == .reading {
            let trackOutput = assetReader.outputs.first!

            if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let blockBufferLength = CMBlockBufferGetDataLength(blockBuffer)
                let sampleLength = CMSampleBufferGetNumSamples(sampleBuffer) * channelCount(from: assetReader)
                var data = Data(capacity: blockBufferLength)
                data.withUnsafeMutableBytes { (blockSamples: UnsafeMutablePointer<Int16>) in
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, blockBufferLength, blockSamples)
                    CMSampleBufferInvalidate(sampleBuffer)

                    let processedSamples = process(blockSamples,
                                                   ofLength: sampleLength,
                                                   from: assetReader,
                                                   downsampledTo: targetSampleCount)

                    outputSamples += processedSamples
                }
            }
        }
        var paddedSamples = [Float](repeating: silenceDbThreshold, count: targetSampleCount)
        paddedSamples.replaceSubrange(0..<min(targetSampleCount, outputSamples.count), with: outputSamples)
        
        return paddedSamples
    }

    fileprivate static func normalize(_ samples: [Float]) -> [Float] {
        return samples.map { self.getLevel(from: $0) }
    }

    private static func process(_ samples: UnsafeMutablePointer<Int16>,
                                ofLength sampleLength: Int,
                                from assetReader: AVAssetReader,
                                downsampledTo targetSampleCount: Int) -> [Float] {
        var loudestClipValue: Float = 0.0
        var quietestClipValue = silenceDbThreshold
        var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
        let samplesToProcess = vDSP_Length(sampleLength)

        var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
        vDSP_vflt16(samples, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1)
        vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

        let samplesPerPixel = max(1, sampleCount(from: assetReader) / targetSampleCount)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        let downSampledLength = sampleLength / samplesPerPixel
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)

        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter,
                    &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))

        return downSampledData
    }

    private static func sampleCount(from assetReader: AVAssetReader) -> Int {
        let samplesPerChannel = Int(assetReader.asset.duration.value)
        return samplesPerChannel * channelCount(from: assetReader)
    }

    private static func channelCount(from assetReader: AVAssetReader) -> Int {
        let audioTrack = (assetReader.outputs.first as? AVAssetReaderTrackOutput)?.track

        var channelCount = 0
        audioTrack?.formatDescriptions.forEach { formatDescription in
            let audioDescription = CFBridgingRetain(formatDescription) as! CMAudioFormatDescription
            if let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioDescription) {
                channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
            }
        }
        return channelCount
    }
}

// MARK: - Configuration

fileprivate extension AudioProcessor {
    fileprivate static func outputSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}
