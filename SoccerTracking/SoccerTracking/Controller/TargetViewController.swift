//
//  TargetViewController.swift
//  SoccerTracking
//
//  Created by Leonardo Alves de Melo on 15/09/17.
//  Copyright © 2017 Gustavo De Mello Crivelli. All rights reserved.
//

import AVFoundation
import Vision
import UIKit

class TargetViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var contando:Bool = false
    var runningData:[(Double, Double)] = [] //Distance x time

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var distanceTextField: UITextField!
    @IBOutlet weak var okDistanceButton: UIButton!
    @IBOutlet weak var insertDistanceView: UIView!
    @IBOutlet weak var finishLineImage: UIImageView!
    @IBOutlet weak var initLineImage: UIImageView!
    @IBOutlet weak var finishImage: UIImageView!
    @IBOutlet weak var initImage: UIImageView!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var highlightView: UIView! {
        didSet {
            self.highlightView?.layer.borderColor = UIColor.red.cgColor
            self.highlightView?.layer.borderWidth = 4
            self.highlightView?.backgroundColor = .clear
        }
    }
    
    @IBOutlet weak var cameraView: UIView!
    private let visionSequenceHandler = VNSequenceRequestHandler()
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()
    
    var start : DispatchTime!
    var end : DispatchTime!
    var now : DispatchTime!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        finishLineImage.alpha = CGFloat(0)
        finishImage.alpha = CGFloat(0)
        self.playButton.alpha = CGFloat(0)
        insertDistanceView.layer.cornerRadius = 5
        okDistanceButton.layer.cornerRadius = 5
        
        
        informationLabel.text = "Arraste os marcadores para os pontos de largada e chegada"
        informationLabel.backgroundColor?.withAlphaComponent(CGFloat(0.4))
        
        insertDistanceView.alpha = CGFloat(0)
        
        // hide the red focus area on load
        self.highlightView?.frame = .zero
        
        // make the camera appear on the screen
        self.cameraView?.layer.addSublayer(self.cameraLayer)
        
        // register to receive buffers from the camera
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        
        // begin the session
        self.captureSession.startRunning()
        
        finishImage.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(TargetViewController.drag(_:))))
        initImage.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(TargetViewController.drag(_:))))
        
        
        
        
        
    }
    
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        // get the center of the tap
        self.highlightView?.frame.size = CGSize(width: 120, height: 120)
        self.highlightView?.center = sender.location(in: self.view)
        
        // convert the rect for the initial observation
        let originalRect = self.highlightView?.frame ?? .zero
        var convertedRect = self.cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        
        // set the observation
        let newObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
        self.lastObservation = newObservation
    }
    
    
    
    private var lastObservation: VNDetectedObjectObservation?
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            // make sure the pixel buffer can be converted
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            // make sure that there is a previous observation we can feed into the request
            let lastObservation = self.lastObservation
            else { return }
        
        // create the request
        let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation, completionHandler: self.handleVisionRequestUpdate)
        // set the accuracy to high
        // this is slower, but it works a lot better
        request.trackingLevel = .accurate
        
        // perform the request
        do {
            try self.visionSequenceHandler.perform([request], on: pixelBuffer)
        } catch {
            print("Throws: \(error)")
        }
    }
    
    private func handleVisionRequestUpdate(_ request: VNRequest, error: Error?) {
        // Dispatch to the main queue because we are touching non-atomic, non-thread safe properties of the view controller
        DispatchQueue.main.async {
            // make sure we have an actual result
            guard let newObservation = request.results?.first as? VNDetectedObjectObservation else { return }
            
            // prepare for next loop
            self.lastObservation = newObservation
            
            // check the confidence level before updating the UI
            guard newObservation.confidence >= 0.3 else {
                // hide the rectangle when we lose accuracy so the user knows something is wrong
                self.highlightView?.frame = .zero
                return
            }
            
            // calculate view rect
            var transformedRect = newObservation.boundingBox
            transformedRect.origin.y = 1 - transformedRect.origin.y
            let convertedRect = self.cameraLayer.layerRectConverted(fromMetadataOutputRect: transformedRect)
            
            // move the highlight view
            self.highlightView?.frame = convertedRect
            
            if(self.contando) {
                self.setDistance()
            }
            

        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // make sure the layer is the correct size
        self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
//    @IBAction func readyButtonClicked(_ sender: Any) {
//
//        let finishPosition = finishImage.center
//        let initPosition = initImage.center
//
//
//        print(finishPosition)
//        print(initPosition)
//
//        readyButton.layer.opacity = 0
//
//    }
    @IBAction func okDistanceButtonClicked(_ sender: UIButton) {
        
        let finishPosition = finishImage.center
        let initPosition = initImage.center


        print(finishPosition)
        print(initPosition)
        
        let distance = Double(distanceTextField.text!)!
        
        print(distance)
        
        insertDistanceView.removeFromSuperview()
    }
    
    func setDistance() {
        
        self.now = DispatchTime.now()
        
        let nanoTime = now.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
        
        guard timeInterval > 0 else { return }
        
        let distanceBetweenMarkersInMeters = 50
        
        let finishPosition = finishImage.center
        let initPosition = initImage.center
        
        let distanceBetweenMarkersInPixels = finishPosition.x - initPosition.x
        
        let distanceRanSoFar = ((highlightView?.frame.minX)! + (highlightView?.frame.width)! / 2) - initPosition.x
        
        let percentageRan = distanceRanSoFar / distanceBetweenMarkersInPixels
        print(percentageRan)
        
        //informationLabel.text = "\(timeInterval)s"
        runningData.append((Double(distanceBetweenMarkersInMeters) * Double(percentageRan), timeInterval))
        if percentageRan >= 1 {
            contando = false
            performSegue(withIdentifier: "showGraph", sender: nil)
        }
        
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showGraph") {
            if let vc = segue.destination as? ResultsViewController {
                vc.distanceTimeData = self.runningData
            }
        }
    }
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
        contando = true
        start = DispatchTime.now()
    }
    
    @IBAction func beginEditingDistanceTextField(_ sender: UITextField) {
        
    }
    
    @IBAction func valueChangedDistanceTextField(_ sender: Any) {
        print("eu")
    }
    @objc func drag(_ recognizer:UIPanGestureRecognizer) {
        
        if(recognizer.state == .ended) {
            if(recognizer.view == self.initImage) {
                finishLineImage.alpha = CGFloat(1)
                finishImage.alpha = CGFloat(1)
                //informationLabel.text = "Arraste o marcador para o ponto de chegada"
            }
            if(recognizer.view == self.finishImage) {
                //insertDistanceView.alpha = CGFloat(1)
                
                self.playButton.alpha = CGFloat(1)
                
            }
        }

        
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint(x:0, y:0), in: self.view)
        
        initLineImage.center.x = initImage.center.x
        finishLineImage.center.x = finishImage.center.x
    }
}
