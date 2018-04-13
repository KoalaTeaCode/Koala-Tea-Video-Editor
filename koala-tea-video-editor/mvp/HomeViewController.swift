//
//  HomeViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 4/8/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import SoundWave
import KoalaTeaPlayer
import AVFoundation
import ZHWaveform

class HomeViewController: UIViewController {
    var player: AssetPlayer!
    var audioPlayer: AVAudioPlayer!
    var button: UIButton!
    var audioVisualizationView: AudioVisualizationView!

    var meters = [Float]()

    lazy var waveform: ZHWaveformView = {
        let bundle = Bundle(for: type(of: self)) // music
        let waveform = ZHWaveformView(
            frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 75),
            fileURL: bundle.url(forResource: "party", withExtension: "wav")!
        )
//        waveform.croppedDelegate = self
        return waveform
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = .gray
        waveform.backgroundColor = .clear
//        self.view.addSubview(waveform)

        let path = Bundle.main.path(forResource: "party.wav", ofType: nil)!
//        let path = Bundle.main.path(forResource: "badday.mp3", ofType: nil)!
        let url = URL(fileURLWithPath: path)

        audioPlayer = try! AVAudioPlayer(contentsOf: url)
        audioPlayer.enableRate = true
        audioPlayer.isMeteringEnabled = true
        audioPlayer.volume = 0.0
        let rate: Float = 1
        audioPlayer.rate = rate
//        audioPlayer.play()

//        let firstTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (timer) in
//            self.audioPlayer.updateMeters()
//
//            let averagePower = self.audioPlayer.averagePower(forChannel: 0)
////            print(peakPower,"peak")
////            let number = self.convertToRange(number: Double(peakPower), inputMin: -160, inputMax: 0.001, rangeMax: 1)
////            print(number, "n")
////            audioVisualizationView.addMeteringLevel(Float(number))
//
////            let percentage = self.getLevel(from: averagePower)
////            self.meters.append(percentage)
////            audioVisualizationView.addMeteringLevel(percentage)
////            let converted = (peakPower + 160) / 160
////            print(converted)
////            audioVisualizationView.addMeteringLevel(Float(converted))
//        }
//
//        let time = 5 / Double(rate)
//        Timer.scheduledTimer(withTimeInterval: time, repeats: false) { (timer) in
//            firstTimer.invalidate()
////            self.audioPlayer.stop()
//
////            self.audioVisualizationView = AudioVisualizationView()
////            self.audioVisualizationView.frame = CGRect(x: 20, y: 0, width: self.view.width - 40, height: 100)
////
////
////            self.audioVisualizationView.audioVisualizationMode = .read
////            self.audioVisualizationView.meteringLevels = self.meters
////            self.view.addSubview(self.audioVisualizationView)
//        }

        button = UIButton(frame: CGRect(x: 0, y: 300, width: 100, height: 75))
        button.setTitle("play", for: .normal)
        button.setTitle("pause", for: .selected)
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        button.backgroundColor = .magenta

        self.view.addSubview(button)

        let audioAsset = AVURLAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "party.wav", ofType: nil)!))
        guard let assetReader = try? AVAssetReader(asset: audioAsset),
            let _ = audioAsset.tracks.first else {
                return
        }

        let desiredWidth = self.view.width
        let audioDuration = 3.17
        let samplesPerSecond = 120.0
        let sampleCount = samplesPerSecond * audioDuration

        let widthPerSecond = desiredWidth.double / audioDuration
        let totalWidthForWaveformAndSpacing = widthPerSecond / samplesPerSecond

        // Calculate spacing and waveform width
        // Spacing is 1/3 available space
        let spacing = totalWidthForWaveformAndSpacing / 3
        // Waveform is the other 2/3
        let singleWaveWidth = totalWidthForWaveformAndSpacing - (spacing)

        //------------------------- Custom output no calculation
//        let waveformWidth = 8.0
//        let spacing = 2.0
//
//        let samplesPerSecond = 41.0
//        let audioDuration = 3.17
//        let sampleCount = samplesPerSecond * audioDuration
//
//        let totalWidth = (waveformWidth + spacing) * sampleCount

        // Start with:
        // samples
        // single wave width
        // Spacing
        // total desired width

        let audioProcessor = AudioProcessor()
        let samples = audioProcessor.waveformSamples(from: assetReader, count: Int(sampleCount))

        // @TODO: Calculate spacing from width

        self.generateFullWaveform(samples: samples!, totalWidth: desiredWidth, singleWaveWidth: 2, spacing: 0)

//        for (index, sample) in samples!.enumerated() {
//            var height = (sample * 2) * 100
//            if height <= 0 {
//                height = (0.01 * 2) * 100
//            }
//            let view = UIView(frame: CGRect(x: index.double * (waveformWidth + spacing), y: 0.0, width: waveformWidth, height: height.double))
//            view.backgroundColor = .yellow
////            view.cornerRadius = view.width / 2
//            scrollView.addSubview(view)
//        }

//        scrollView.contentSize = CGSize(width: CGFloat(desiredWidth), height: scrollView.height)

//        var tim: Double = 0.0
//        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { (timer) in
//            tim += timer.timeInterval.cgFloat.double
//            // Calculate size per second
//            let pointsPerSecond: Double =  Double(scrollView.contentSize.width) / 3.15
//            // Calculate x scroll value
//            let x = tim * (pointsPerSecond)
//            let y = scrollView.contentOffset.y
//
//            // Scroll to time
//            let frame = CGRect(x: x, y: Double(y), width: 0.001, height: 0.001)
//            print(x)
//            scrollView.scrollRectToVisible(frame, animated: false)
//
//            if tim >= 3.15 {
//                timer.invalidate()
//            }
//        }
    }

    @objc func buttonPressed() {
        self.audioPlayer.currentTime = 0.0
        self.audioPlayer.rate = 1
        self.audioPlayer.volume = 1.0
        switch self.button.isSelected {
        case true:
            self.audioPlayer.stop()
            self.audioPlayer.currentTime = 0.0
//            self.audioVisualizationView.pause()
        case false:
            self.audioPlayer.play()
//            self.audioVisualizationView.play(for: 3)
        }

        self.button.isSelected = !self.button.isSelected

//        var index = 0
//        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (timer) in
//            index += 1
//
//            guard let meter = self.meters.item(at: index) else {
//                return
//            }
//
//            if meter >= 0.3 {
//                self.view.backgroundColor = .red
//            } else {
//                self.view.backgroundColor = .gray
//            }
//        }
    }

    func generateFullWaveform(samples: [Float], totalWidth: CGFloat, singleWaveWidth: CGFloat, spacing: CGFloat) {
        // @TODO: Add min spacing if spacing <= 0
        // @TODO: have to fix cluster to accept more than rounded int for ^ to work

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 50, width: self.view.width, height: 300))
        scrollView.backgroundColor = .lightGray

        self.view.addSubview(scrollView)

        let finalWaveCount = totalWidth / (singleWaveWidth + spacing)

        // samples.count / clustersize = final number of items
        let clusterSize = samples.count.double / finalWaveCount.double

        let averageArray = self.clusterAndGetAverages(array: samples, clusterSize: (clusterSize * 10.0).rounded() / 10.0)
        print(averageArray.count)
        for (index, sample) in averageArray.enumerated() {

            var height = (sample * 2) * 100
            if height <= 0 {
                height = (0.005 * 2) * 100
            }

            let x = index.cgFloat * (singleWaveWidth + spacing)
            let view = UIView(frame: CGRect(x: x,
                                            y: scrollView.height / 2,
                                            width: singleWaveWidth,
                                            height: height.cgFloat))
            view.backgroundColor = .yellow
            view.cornerRadius = view.width / 2

            let topViewY = scrollView.height / 2 - view.height
            let topView = UIView(frame: view.frame)
            topView.y = topViewY
            topView.cornerRadius = view.cornerRadius
            topView.backgroundColor = view.backgroundColor

            scrollView.addSubview(topView)
            scrollView.addSubview(view)

            if x > totalWidth {
                print("yes is over")
            }
        }
    }

    func clusterAndGetAverages(array: [Float], clusterSize: Double) -> [Float] {
        return self.filterAndAverage(cluster: self.cluster(array: array, by: clusterSize))
    }

    func cluster(array: [Float], by clusterSize: Double) -> [[Float]] {
        var clusters = [[Float]]()
        var currentCluster = [Float]()

        var counter: Double = 1
        for item in array {
            print(counter / clusterSize, "test")
//            print(counter.truncatingRemainder(dividingBy: clusterSize))
            guard (counter / clusterSize) == 0 else {
//            guard counter.truncatingRemainder(dividingBy: clusterSize) == 0 else {
                // Add item to current cluster
                currentCluster.append(item)

                counter += 1

                if (counter - 1).int == array.count {
                    clusters.append(currentCluster)
                }

                continue
            }

            // Cluster has reached a divisable of our clusterSize
            // Need to create a new array
            clusters.append(currentCluster)
            currentCluster = []
            currentCluster.append(item)
            counter += 1
        }

        return clusters
    }

    func filterAndAverage(cluster: [[Float]]) -> [Float] {
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension Array where Element: Numeric {
    /// Returns the total sum of all elements in the array
    var total: Element { return reduce(0, +) }
}

extension Array where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    var average: Double {
        return isEmpty ? 0 : Double(Int(total)) / Double(count)
    }
}

extension Array where Element: FloatingPoint {
    /// Returns the average of all elements in the array
    var average: Element {
        return isEmpty ? 0 : total / Element(count)
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

struct AudioProcessor {
    func waveformSamples(from assetReader: AVAssetReader, count: Int) -> [Float]? {
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
    func getLevel(from decibels: Float) -> Float {
        var level: Float = 0.0
        // The linear 0.0 .. 1.0 value we need.
        let minDecibels: Float = -160.0

        if decibels < minDecibels {
            level = 0.0
        } else if decibels >= 0.0 {
            level = 1.0
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
    private var silenceDbThreshold: Float { return -160.0 } // everything below -50 dB will be clipped

    fileprivate func extract(samplesFrom assetReader: AVAssetReader, downsampledTo targetSampleCount: Int) -> [Float] {
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

    fileprivate func normalize(_ samples: [Float]) -> [Float] {
        return samples.map { self.getLevel(from: $0) }
    }

    private func process(_ samples: UnsafeMutablePointer<Int16>,
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

    private func sampleCount(from assetReader: AVAssetReader) -> Int {
        let samplesPerChannel = Int(assetReader.asset.duration.value)
        return samplesPerChannel * channelCount(from: assetReader)
    }

    // swiftlint:disable force_cast
    private func channelCount(from assetReader: AVAssetReader) -> Int {
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
    // swiftlint:enable force_cast
}

// MARK: - Configuration

fileprivate extension AudioProcessor {
    fileprivate func outputSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}
