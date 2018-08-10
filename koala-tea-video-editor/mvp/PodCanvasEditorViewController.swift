//
//  PodCanvasEditorViewController.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 4/14/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import Photos

// 1280x1024 twitter vid
// 1024x1024 facebook vid

class PodCanvasEditorViewController: UIViewController {
    var samples: [Float]
    var startTime: Double
    var endTime: Double
    var duration: Double
    var fileURL: URL
    
    var draggableContainerView: DraggableView!
    var imageView: UIImageView!

    var canvasContentView: UIView!

    var label: UILabel!
    var continueButton = UIButton()

    var currentExportSize: VideoExportManager.VideoExportSizes = ._1280x1024_twitter

    required init(samples: [Float], startTime: Double, endTime: Double, fileURL: URL) {
        self.samples = samples
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime - startTime
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        let buttonSize = CGSize(width: self.view.width / 2 - 20, height: 42)

        let canvasView = UIView(frame: CGRect(x: 0, y: 20, width: self.view.width, height: self.view.width))
        canvasView.backgroundColor = UIColor(red: 0.152941182255745, green: 0.149019613862038, blue: 0.152941182255745, alpha: 1.0)
        self.view.addSubview(canvasView)

//        let size = CanvasFrameSizes._1x1(forSize: CGSize(width: canvasView.width, height: canvasView.height)).rawValue
        let size = CanvasFrameSizes.twitter(forSize: CGSize(width: canvasView.width, height: canvasView.height)).rawValue
        let y = (canvasView.height - size.height) / 2
        canvasContentView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: y), size: size))
        canvasContentView.backgroundColor = .lightGray
        canvasContentView.clipsToBounds = true

        canvasView.addSubview(canvasContentView)

        self.draggableContainerView = DraggableView(frame: .zero)
        self.imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        draggableContainerView.addSubview(imageView)

        canvasContentView.addSubview(draggableContainerView)

        label = UILabel(frame: CGRect(x: 8, y: 8, width: canvasContentView.width - 16, height: 100))
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.text = "Double Tap To Edit"
        label.numberOfLines = 0

        label.font = UIFont.systemFont(ofSize: UIView.getValueScaledByScreenWidthFor(baseValue: 40))
        label.adjustsFontSizeToFitWidth = true
        self.setLabelHeight()

        label.textColor = .white
        label.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didDoubleTapLabel(_:)))
        tapGesture.numberOfTapsRequired = 2
        label.addGestureRecognizer(tapGesture)

        self.canvasContentView.addSubview(label)

        let backgroundWaveView = self.getWaveView(samples: self.samples, totalWidth: self.view.width - 20)
        self.canvasContentView.addSubview(backgroundWaveView)
        for view in backgroundWaveView.subviews {
            view.backgroundColor = UIColor(red:1.00, green:0.74, blue:0.00, alpha:1.0)
        }
        // Wave view
        let waveView = self.getWaveView(samples: self.samples, totalWidth: self.view.width - 20)
        self.canvasContentView.addSubview(waveView)

        // Bottom view
        let bottomView = UIView(frame: CGRect(x: 0, y: canvasView.frame.maxY, width: self.view.width, height: self.view.height - canvasView.height - 20))
        self.view.addSubview(bottomView)

        let buttonColor = UIColor(red: 0.203921568627451, green: 0.552941176470588, blue: 0.768627450980392, alpha: 1.0)

        let changeImageButton = UIButton(frame: CGRect(origin: CGPoint(x: bottomView.frame.maxX - buttonSize.width - 10, y: 10), size: buttonSize))
        changeImageButton.cornerRadius = changeImageButton.height / 2
        changeImageButton.setTitle("Set Image", for: .normal)
        changeImageButton.backgroundColor = buttonColor
        changeImageButton.addTarget(self, action: #selector(self.changeImageButtonPressed), for: .touchUpInside)
        bottomView.addSubview(changeImageButton)

        let resetImageButton = UIButton(frame: CGRect(origin: CGPoint(x: bottomView.frame.maxX - buttonSize.width - 10, y: changeImageButton.frame.maxY + 10), size: buttonSize))
        resetImageButton.cornerRadius = changeImageButton.height / 2
        resetImageButton.setTitle("Reset Image", for: .normal)
        resetImageButton.backgroundColor = buttonColor
        resetImageButton.addTarget(self, action: #selector(self.resetImageButtonPressed), for: .touchUpInside)
        bottomView.addSubview(resetImageButton)

        continueButton = UIButton(frame: CGRect(origin: CGPoint(x: bottomView.frame.maxX - buttonSize.width - 10, y: bottomView.bounds.maxY - buttonSize.height - 10), size: buttonSize))
        continueButton.cornerRadius = continueButton.height / 2
        continueButton.setTitle("Export", for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        continueButton.backgroundColor = buttonColor
        bottomView.addSubview(continueButton)

        let changeFormatButton = UIButton(frame: CGRect(origin: CGPoint(x: 10, y: bottomView.bounds.maxY - buttonSize.height - 10), size: buttonSize))
        changeFormatButton.cornerRadius = continueButton.height / 2
        changeFormatButton.setTitle("Format", for: .normal)
        changeFormatButton.addTarget(self, action: #selector(changeFormatButtonPressed), for: .touchUpInside)
        changeFormatButton.backgroundColor = buttonColor
        bottomView.addSubview(changeFormatButton)

        let backButton = UIButton(frame: CGRect(origin: CGPoint(x: 10, y: 10), size: buttonSize))
        backButton.cornerRadius = backButton.height / 2
        backButton.backgroundColor = UIColor(red: 0.725490196078431, green: 0.0313725490196078, blue: 0.0470588235294118, alpha: 1.0)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(self.exit), for: .touchUpInside)
        bottomView.addSubview(backButton)

        let x = (waveView.x + (waveView.width / 2)) + waveView.width

        let path = UIBezierPath(rect: waveView.bounds)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        waveView.layer.mask = maskLayer

        // Not sure why more time needs to be added to duration
        let animationDuration = self.duration + (self.duration / 2)
        waveView.layer.mask!.changePositionX(to: NSNumber(value: x.double), beginTime: 0.0001, duration: animationDuration)
    }

    @objc func exit() {
        self.navigationController?.popViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func continueButtonPressed() {
        let urlpath = Bundle.main.path(forResource: "onesecondvideo", ofType: "mp4")
        let tempurl = NSURL.fileURL(withPath: urlpath!)
        let videoAsset2 = VideoAsset(assetName: "", url: tempurl)

        let videoAsset = VideoAsset(assetName: "", url: self.fileURL)
        videoAsset.setStartime(to: self.startTime)
        videoAsset.setEndTime(to: self.endTime)

        let sv = self.displayDownloadSpinner()

        VideoExportManager.exportVideoTest(with: [videoAsset,videoAsset2], canvasViewFrame: self.canvasContentView.frame, finalExportSize: self.currentExportSize, viewToAdd: self.canvasContentView, progress: { (progress) in
            DispatchQueue.main.async {
                sv.downloadProgressView.configureProgressLabel(withFraction: Double(progress))
            }
        }, success: {
            DispatchQueue.main.async {
                sv.removeWithAnimation()

                self.navigationController?.popViewController({
                    let alert = UIAlertController(title: "Successfully exported!")
                    alert.show()
                })
            }
        }) { (error) in
            DispatchQueue.main.async {
                sv.removeWithAnimation()

                self.navigationController?.popViewController({
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, defaultActionButtonTitle: "Okay", tintColor: nil)
                    alert.show()
                })
            }
        }

        sv.didCancelHandler = { () -> Void in
            self.navigationController?.popViewController()
        }
    }

    @objc func changeFormatButtonPressed() {
        let actionSheet = UIAlertController(title: "Change Final Video Format", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(title: "Twitter: 1280x1024", style: .default, isEnabled: true) { (action) in
            UIView.animate(withDuration: 0.15, animations: {
                let size = CanvasFrameSizes.twitter(forSize: CGSize(width: self.view.width, height: self.view.width)).rawValue
                self.canvasContentView.size = size
                let y = (self.view.width - size.height) / 2
                self.canvasContentView.frame.origin = CGPoint(x: 0, y: y)

                self.currentExportSize = ._1280x1024_twitter
            })
        }
        actionSheet.addAction(title: "Facebook: 1024x1024", style: .default, isEnabled: true) { (action) in
            UIView.animate(withDuration: 0.15, animations: {
                self.canvasContentView.size = CanvasFrameSizes._1x1(forSize: CGSize(width: self.view.width, height: self.view.width)).rawValue
                self.canvasContentView.frame.origin = .zero

                self.currentExportSize = ._1024x1024
            })
        }
        actionSheet.addAction(title: "Cancel")
        actionSheet.show()
    }

    func getWaveView(samples: [Float], totalWidth: CGFloat) -> UIView {
        let singleWaveWidth = 2.0
        let spacing = singleWaveWidth * 0.75

        // Using audioDuration * 24 or 24 waveforms per second as a baseline for showing this type of waveView
        //        let totalWidth = (singleWaveWidth + spacing) * (audioDuration * 24)
        // 130p per second
//        let totalWidth = 130 * audioDuration
        let waveView = WaveformGenerator.generateFullWaveform(samples: samples, totalWidth: totalWidth, height: 125, singleWaveWidth: singleWaveWidth.cgFloat, spacing: spacing.cgFloat)
        waveView.isUserInteractionEnabled = false
        waveView.x += 10
        waveView.y = canvasContentView.bounds.maxY - waveView.height - 30

        return waveView
    }

    @objc func changeImageButtonPressed() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController , animated: true, completion: nil)
    }

    @objc func resetImageButtonPressed() {
        self.resetDraggableContainerView(image: self.imageView.image!)
    }

    @objc func didDoubleTapLabel(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Enter New Text", message: "", preferredStyle: .alert)
        alert.addTextField(text: label.text, placeholder: "", editingChangedTarget: self, editingChangedSelector: #selector(self.alertTextFieldChanged(_:)))
        alert.textFields?.first?.clearButtonMode = .always

        alert.addAction(title: "Done", style: .default, isEnabled: true) { (action) in
            if self.label.text!.count <= 0 {
                self.label.text = "Double Tap To Edit"
                self.setLabelHeight()
            }
        }
        self.present(alert, animated: true, completion: nil)
    }

    @objc func alertTextFieldChanged(_ sender: UITextField) {
        label.text = sender.text
        setLabelHeight()
    }

    func setLabelHeight() {
        // Less than max height else lower font size
        guard label.requiredHeight <= 145 else {
            // Lower font size proportionally
            return
        }

        label.height = label.requiredHeight
    }

    func resetDraggableContainerView(image: UIImage) {
        self.draggableContainerView.transform = CGAffineTransform.identity
        self.draggableContainerView.x = 0
        self.draggableContainerView.y = 0
        self.draggableContainerView.size = image.size.aspectFill(to: self.canvasContentView.size)

        self.imageView.image = image
        self.imageView.frame = self.draggableContainerView.frame
    }
}

extension PodCanvasEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.resetDraggableContainerView(image: pickedImage)
        }

        picker.dismiss(animated: true, completion: nil)

        continueButton.isHidden = false
    }
}
