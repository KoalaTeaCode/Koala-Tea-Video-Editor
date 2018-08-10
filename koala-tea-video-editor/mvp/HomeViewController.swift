//
//  HomeViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 4/8/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import KoalaTeaPlayer
import AVFoundation
import Alamofire

class HomeViewController: UIViewController {
    var fileURL: URL?
    var samples: [Float]?

    var urlTextField = UITextField()
    var editAudioButton = UIButton()
    var continueButton = UIButton()

    var startTime = 0.0
    var endTime = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonColor = UIColor(red: 0.203921568627451, green: 0.552941176470588, blue: 0.768627450980392, alpha: 1.0)

        let textFieldWidth = self.view.width - 16
        let textFieldX = self.view.center.x - textFieldWidth / 2
        urlTextField.frame = CGRect(x: textFieldX, y: 20, width: textFieldWidth, height: 42)
        urlTextField.placeholder = "Enter an audio URL"
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.textColor = buttonColor
        urlTextField.tintColor = buttonColor
        urlTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.view.addSubview(urlTextField)

        let buttonSize = CGSize(width: self.view.width / 2 - 20, height: 42)
        let cornerRadius = buttonSize.height / 2

        let x = self.view.center.x - buttonSize.width / 2
        let spacing: CGFloat = 10

        editAudioButton = UIButton(frame: CGRect(origin: CGPoint(x: x, y: urlTextField.bottomLeftPoint().y + spacing), size: buttonSize))
        editAudioButton.cornerRadius = cornerRadius
        editAudioButton.setTitle("Edit Audio", for: .normal)
        editAudioButton.addTarget(self, action: #selector(editAudioButtonPressed), for: .touchUpInside)
        editAudioButton.backgroundColor = buttonColor


        continueButton = UIButton(frame: CGRect(origin: CGPoint(x: x, y: editAudioButton.bottomLeftPoint().y + spacing), size: buttonSize))
        continueButton.cornerRadius = cornerRadius
        continueButton.setTitle("Continue", for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        continueButton.backgroundColor = buttonColor
        continueButton.isHidden = true

        self.view.addSubview(editAudioButton)
        self.view.addSubview(continueButton)

        // @TODO: Remove this
        urlTextField.text = "http://traffic.libsyn.com/sedaily/2018_04_30_EpicenterBitcoin.mp3"
//        urlTextField.text = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func editAudioButtonPressed() {
        self.editAudioButton.isEnabled = false

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            assertionFailure("File manager issue")
            return
        }
        let fileURL = documentsURL.appendingPathComponent("audio.mp3")

        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        guard let text = self.urlTextField.text else {
            // Alert please enter text
            let alert = UIAlertController(title: "Error", message: "Please enter text into text field", defaultActionButtonTitle: "Okay", tintColor: nil)
            self.present(alert, animated: true, completion: nil)
            self.editAudioButton.isEnabled = true
            return
        }

        guard let url = URL(string: text) else {
            // Alert text is not valid
//            let alert = UIAlertController(title: "Error", message: "Text is not a URL", defaultActionButtonTitle: "Okay", tintColor: nil)
//            self.present(alert, animated: true, completion: nil)
//            self.editAudioButton.isEnabled = true
            // @FIXME: remove
            let urlpath = Bundle.main.path(forResource: "badday", ofType: "mp3")
            let tempurl = NSURL.fileURL(withPath: urlpath!)
            self.fileURL = tempurl
            let vc = AudioEditorViewController(fileURL: tempurl, samples: nil)
            vc.delegate = self
            self.navigationController?.pushViewController(vc)
            self.editAudioButton.isEnabled = true
            return
        }

        guard self.samples == nil || self.samples!.count < 0 else {
            let vc = AudioEditorViewController(fileURL: fileURL, samples: self.samples)
            vc.delegate = self
            self.navigationController?.pushViewController(vc)
            self.editAudioButton.isEnabled = true
            return
        }

        // @TODO: put in self.samples check and fileurl check
        let sv = self.displayDownloadSpinner()

        let request = Alamofire.download(url, to: destination).downloadProgress(closure: { (progress) in
            sv.downloadProgressView.configureProgressLabel(withFraction: progress.fractionCompleted)
        }).responseData { (response) in
            switch response.result {
            case .success:
                self.fileURL = fileURL
                let vc = AudioEditorViewController(fileURL: fileURL, samples: nil)
                vc.delegate = self
                self.navigationController?.pushViewController(vc, completion: {
                    self.editAudioButton.isEnabled = true
                    sv.removeWithAnimation()
                })
                break
            case .failure(let error):
                sv.removeWithAnimation()
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, defaultActionButtonTitle: "Okay", tintColor: nil)
                self.present(alert, animated: true, completion: nil)
                self.editAudioButton.isEnabled = true
            }
        }

        sv.didCancelHandler = { () -> Void in
            request.cancel()
        }
    }

    @objc func continueButtonPressed() {
        guard let samples = self.samples else {
            print("Some issue with samples")
            return
        }
        
        let filteredSamples = self.getCutSamples(from: samples, startTime: startTime, endTime: endTime)

        let vc = PodCanvasEditorViewController(samples: filteredSamples, startTime: self.startTime, endTime: self.endTime, fileURL: self.fileURL!)
        self.navigationController?.pushViewController(vc)
    }

    func getCutSamples(from samples: [Float], startTime: Double, endTime: Double) -> [Float] {

        // Get samples counts for start and end time
        let startCount = startTime * 1000
        let endCount = endTime * 1000

        var filteredSamples = [Float]()
        // Find all indexes between start and end time
        for (index, sample) in samples.enumerated() {
            if index > startCount.int && index < endCount.int {
                filteredSamples.append(sample)
            }
        }

        return filteredSamples
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        self.fileURL = nil
        self.samples = nil
        self.continueButton.isHidden = true
    }
}

extension HomeViewController: AudioEditorViewControllerDelegate {
    func samplesSet(samples: [Float]) {
        self.samples = samples
    }

    func didFinishPicking(timeRange: CMTimeRange) {
        self.navigationController?.popViewController()

        self.editAudioButton.setTitle("Audio Set ✔️", for: .normal)
        self.editAudioButton.backgroundColor = UIColor(red: 0.403921574354172, green: 0.803921580314636, blue: 0.564705908298492, alpha: 1.0)

        self.continueButton.isHidden = false

        self.startTime = timeRange.start.seconds
        self.endTime = timeRange.end.seconds
    }
}

class ScreenView: UIView {
    var didCancelHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didFireTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 5
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didFireTapGesture(_ sender: UITapGestureRecognizer) {
        if let handler = didCancelHandler {
            handler()
        }
        self.removeFromSuperview()
    }
}

class DownloadScreenView: ScreenView {
    var downloadProgressView: DownloadProgressView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.downloadProgressView = DownloadProgressView(center: self.center)
        self.addSubview(downloadProgressView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DownloadProgressView: UIView {
    var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    required init(center: CGPoint) {
        super.init(frame: .zero)

        self.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        self.center = center
        self.backgroundColor = .white
        self.cornerRadius = 10

        self.progressLabel.size = CGSize(width: 120, height: 40)
        self.progressLabel.center = CGPoint(x: self.width / 2, y: self.height / 2 + 25)
        self.progressLabel.text = "0%"

        let activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = .black
        activityIndicator.startAnimating()
        activityIndicator.center = CGPoint(x: self.width / 2, y: self.height / 2 - 20)

        self.addSubview(progressLabel)
        self.addSubview(activityIndicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureProgressLabel(with progress: Double) {
        let text = progress.int.string + "%"
        self.progressLabel.text = text
    }

    public func configureProgressLabel(withFraction fraction: Double) {
        let roundedProgress = (fraction * 100).rounded()
        self.configureProgressLabel(with: roundedProgress)
    }
}

extension UIViewController {
    func displayDownloadSpinner() -> DownloadScreenView {
        let screenView = DownloadScreenView(frame: self.view.bounds)

        DispatchQueue.main.async {
            self.view.addSubview(screenView)
        }

        return screenView
    }
}

extension UIView {
    func removeWithAnimation() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
