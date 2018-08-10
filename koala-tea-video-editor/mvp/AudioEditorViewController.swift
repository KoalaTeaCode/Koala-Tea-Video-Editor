//
//  AudioEditorViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 4/24/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import KoalaTeaPlayer
import AVFoundation
import Alamofire

protocol AudioEditorViewControllerDelegate: NSObjectProtocol {
    func didFinishPicking(timeRange: CMTimeRange)
    func samplesSet(samples: [Float])
}

class AudioEditorViewController: UIViewController {
    weak var delegate: AudioEditorViewControllerDelegate?

    var fileURL: URL
    var samples: [Float]?

    var player: AssetPlayer!
    var audioPlayer: AVAudioPlayer!
    var isAudioPlayerPaused: Bool = true

    lazy var waveScrollView: WaveformScrollView = {
        let frame = CGRect(x: 0, y: 20, width: self.view.width, height: 300)
        let waveScrollView = WaveformScrollView(frame: frame, videoURL: fileURL, samples: self.samples)
        waveScrollView.backgroundColor = UIColor(red: 0.152941182255745, green: 0.149019613862038, blue: 0.152941182255745, alpha: 1.0)
        waveScrollView.delegate = self

        if self.samples == nil {
            self.samples = waveScrollView.samples
            self.delegate?.samplesSet(samples: self.samples!)
        }

        return waveScrollView;
    }()

    var timer: Timer?

    var playButton = UIButton()
    var pauseButton = UIButton()

    required init(fileURL: URL, samples: [Float]?) {
        self.fileURL = fileURL
        self.samples = samples
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL(fileURLWithPath: fileURL.path)

        try! self.audioPlayer = AVAudioPlayer(contentsOf: url)
        self.audioPlayer!.prepareToPlay()

        self.setupButtons()

        self.view.backgroundColor = .white

        self.view.addSubview(self.waveScrollView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.audioPlayer.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupButtons() {
        let bottomView = UIView(frame: CGRect(x: 0, y: 320, width: self.view.width, height: self.view.height - 320))
        self.view.addSubview(bottomView)

        let buttonColor = UIColor(red: 0.203921568627451, green: 0.552941176470588, blue: 0.768627450980392, alpha: 1.0)
        let buttonSize = CGSize(width: self.view.width / 2 - 20, height: 42)
        let cornerRadius = buttonSize.height / 2

        let x = self.view.center.x - buttonSize.width / 2
        let spacing: CGFloat = 10

        let setStartTimeButton = UIButton(frame: CGRect(origin: CGPoint(x: spacing, y: spacing), size: buttonSize))
        setStartTimeButton.cornerRadius = cornerRadius
        setStartTimeButton.setTitle("Set Start Time", for: .normal)
        setStartTimeButton.addTarget(self, action: #selector(startTimeButtonPressed), for: .touchUpInside)
        setStartTimeButton.backgroundColor = buttonColor

        let setEndTimeButton = UIButton(frame: CGRect(origin: CGPoint(x: bottomView.topRightPoint().x - buttonSize.width - spacing, y: spacing), size: buttonSize))
        setEndTimeButton.cornerRadius = cornerRadius
        setEndTimeButton.setTitle("Set End Time", for: .normal)
        setEndTimeButton.addTarget(self, action: #selector(endTimeButtonPressed), for: .touchUpInside)
        setEndTimeButton.backgroundColor = buttonColor

        playButton = UIButton(frame: CGRect(origin: CGPoint(x: x, y: setStartTimeButton.frame.maxY + spacing), size: buttonSize))
        playButton.cornerRadius = cornerRadius
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        playButton.backgroundColor = buttonColor

        pauseButton = UIButton(frame: CGRect(origin: playButton.frame.origin, size: buttonSize))
        pauseButton.cornerRadius = cornerRadius
        pauseButton.setTitle("Pause", for: .normal)
        pauseButton.addTarget(self, action: #selector(pauseButtonPressed), for: .touchUpInside)
        pauseButton.backgroundColor = buttonColor
        pauseButton.isHidden = true

        let clearTimesButton = UIButton(frame: CGRect(origin: CGPoint(x: x, y: pauseButton.frame.maxY + spacing * 3), size: buttonSize))
        clearTimesButton.cornerRadius = cornerRadius
        clearTimesButton.setTitle("Clear Times", for: .normal)
        clearTimesButton.addTarget(self, action: #selector(clearTimesButtonPressed), for: .touchUpInside)
        clearTimesButton.backgroundColor = buttonColor

        let doneButton = UIButton(frame: CGRect(origin: CGPoint(x: bottomView.topRightPoint().x - buttonSize.width - spacing, y: bottomView.bounds.maxY - buttonSize.height - spacing), size: buttonSize))
        doneButton.cornerRadius = cornerRadius
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        doneButton.backgroundColor = buttonColor

        let cancelButton = UIButton(frame: CGRect(origin: CGPoint(x: spacing, y: bottomView.bounds.maxY - buttonSize.height - spacing), size: buttonSize))
        cancelButton.cornerRadius = cornerRadius
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        cancelButton.backgroundColor = UIColor(red: 0.894117647058824, green: 0.345098039215686, blue: 0.231372549019608, alpha: 1.0)

        bottomView.addSubview(setStartTimeButton)
        bottomView.addSubview(setEndTimeButton)
        bottomView.addSubview(playButton)
        bottomView.addSubview(pauseButton)
        bottomView.addSubview(clearTimesButton)
        bottomView.addSubview(doneButton)
        bottomView.addSubview(cancelButton)
    }

    func startTimer(at time: TimeInterval) {
        self.timer?.invalidate()

        var counter = time
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            if counter >= self.audioPlayer.duration || (self.waveScrollView.endTime != 0 && counter >= self.waveScrollView.endTime) {
                self.pauseAudioPlayer(isAudioPlayerPaused: true)
            }

            counter += timer.timeInterval
            self.waveScrollView.handleTracking(for: counter)
        })
    }

    func stopTimer() {
        self.audioPlayer.stop()
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func playButtonPressed() {
        self.playAudioPlayer(at: self.waveScrollView.startTime)
    }

    @objc func pauseButtonPressed() {
        self.pauseAudioPlayer(isAudioPlayerPaused: true)
    }

    @objc func startTimeButtonPressed() {
        self.waveScrollView.startTime = self.waveScrollView.currentTimeForLinePosition
    }

    @objc func endTimeButtonPressed() {
        self.waveScrollView.endTime = self.waveScrollView.currentTimeForLinePosition
    }

    @objc func clearTimesButtonPressed() {
        self.waveScrollView.clearTimes()
    }

    @objc func doneButtonPressed() {
        let startTime = self.waveScrollView.startTime
        let endTime = self.waveScrollView.endTime

        if (endTime <= startTime) {
            let alertController = UIAlertController(title: "End Time cannot be less than or equal to Start Time")
            self.present(alertController, animated: true, completion: nil)
            return
        }

        // Delegate did finish with start and end time
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 600), end: CMTime(seconds: endTime, preferredTimescale: 600))
        self.delegate?.didFinishPicking(timeRange: timeRange)
    }

    @objc func cancelButtonPressed() {
        self.navigationController?.popViewController()
    }

    func playAudioPlayer(at time: Double) {
        self.audioPlayer.currentTime = time
        self.audioPlayer.play()
        self.isAudioPlayerPaused = false
        self.startTimer(at: time)

        self.playButton.isHidden = true
        self.pauseButton.isHidden = false
    }

    func pauseAudioPlayer(isAudioPlayerPaused: Bool) {
        self.audioPlayer.pause()
        self.isAudioPlayerPaused = isAudioPlayerPaused
        self.stopTimer()

        self.playButton.isHidden = false
        self.pauseButton.isHidden = true
    }
}

extension AudioEditorViewController: WaveformScrollViewDelegate {
    func isScrolling(to time: Double) {
        self.pauseAudioPlayer(isAudioPlayerPaused: isAudioPlayerPaused)
    }

    func endScrolling(to time: Double) {
        self.audioPlayer.currentTime = time
        if (self.isAudioPlayerPaused) {
            return
        }
        self.playAudioPlayer(at: time)
    }
}

class writer: NSObject {
    var assetWriter:AVAssetWriter?
    var assetReader:AVAssetReader?
    let bitrate:NSNumber = NSNumber(value:250000)

    func compressFile(urlToCompress: URL, outputURL: URL, completion:@escaping (URL)->Void){
        //video file to make the asset

        var audioFinished = false
        var videoFinished = false

        let asset = AVAsset(url: urlToCompress);

        //create asset reader
        do{
            assetReader = try AVAssetReader(asset: asset)
        } catch{
            assetReader = nil
        }

        guard let reader = assetReader else{
            fatalError("Could not initalize asset reader probably failed its try catch")
        }

        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!

        let videoReaderSettings: [String:Any] =  [kCVPixelBufferPixelFormatTypeKey as String!:kCVPixelFormatType_32ARGB ]

        // ADJUST BIT RATE OF VIDEO HERE

        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:self.bitrate],
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width
        ]

        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)

        if reader.canAdd(assetReaderVideoOutput){
            reader.add(assetReaderVideoOutput)
        }else{
            fatalError("Couldn't add video output reader")
        }

        if reader.canAdd(assetReaderAudioOutput){
            reader.add(assetReaderAudioOutput)
        }else{
            fatalError("Couldn't add audio output reader")
        }

        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform
        //we need to add samples to the video input

        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")

        do{
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        }catch{
            assetWriter = nil
        }
        guard let writer = assetWriter else{
            fatalError("assetWriter was nil")
        }

        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)

        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: kCMTimeZero)

        let closeWriter:()->Void = {
            if (audioFinished && videoFinished){
                self.assetWriter?.finishWriting(completionHandler: {

                    self.checkFileSize(sizeUrl: (self.assetWriter?.outputURL)!, message: "The file size of the compressed file is: ")

                    completion((self.assetWriter?.outputURL)!)

                })

                self.assetReader?.cancelReading()

            }
        }


        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData){
                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
                if (sample != nil){
                    audioInput.append(sample!)
                }else{
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }

        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            //request data here

            while(videoInput.isReadyForMoreMediaData){
                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
                if (sample != nil){
                    videoInput.append(sample!)
                }else{
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }

        }


    }

    func checkFileSize(sizeUrl: URL, message:String){
        let data = NSData(contentsOf: sizeUrl)!
        print(message, (Double(data.length) / 1048576.0), " mb")
    }
}
