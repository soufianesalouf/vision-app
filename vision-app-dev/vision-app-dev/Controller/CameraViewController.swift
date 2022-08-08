//
//  ViewController.swift
//  vision-app-dev
//
//  Created by Soufiane Salouf on 3/7/18.
//  Copyright © 2018 Soufiane Salouf. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraViewController: UIViewController {

    // MARK: - Views
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData: Data?
    var flashControlState: FlashState = .off
    var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        spinner.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add a tap gesture to take photo
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        // Setup and start a capture session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
        
    }
    
    // MARK: - Local Helpers
    
    @objc func didTapCameraView() {
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        spinner.startAnimating()
        let settings = AVCapturePhotoSettings()

        if flashControlState == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }

        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results  as? [VNClassificationObservation] else { return }
        
        for item in results {
            print("Prediction: \(item.identifier) \nConfidence: \(item.confidence)\n------------------")

        }
        
        guard let predictionResults = results.first else { return }
        
            if predictionResults.confidence < 0.5 {
                
                // Announce to user that we failed to recognize the object
                let unknownObjectMessage = "I'm not sure what this is. Please try again."
                synthesizerSpeech(forString: unknownObjectMessage)
                
                // Set Labels with unknown object message
                self.identificationLbl.text = unknownObjectMessage
                self.confidenceLbl.text = ""
            } else {
                
                // Get the prediction result
                let identification = predictionResults.identifier
                
                // Get the confidence
                let confidence = Int(predictionResults.confidence * 100)
                
                // Announce the prediction to the user
                let completeSentence = "This looks like a \(identification) and I'm \(confidence) percent sure."
                synthesizerSpeech(forString: completeSentence)
                
                // Setup with the prediction results
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "CONFIDENCE: \(confidence)%"
            }
    }
    
    func synthesizerSpeech(forString string: String){
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    
    // MARK: - Actions
    
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            debugPrint(error)
        } else {
            
            // Get the photo data
            photoData = photo.fileDataRepresentation()

            // Set Up Vision with a Core ML Model
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }

            // Add image to the preview container
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
    
}

// MARK: - AVSpeechSynthesizerDelegate##

extension CameraViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
    
}




