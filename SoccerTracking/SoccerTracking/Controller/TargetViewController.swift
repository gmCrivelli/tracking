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
    
    var startPoint : CGPoint = CGPoint.zero
    var finishPoint : CGPoint = CGPoint.zero
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
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
       
        
        readyButton.layer.cornerRadius = 5
        
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
            
            let vec1 : CGVector = CGVector(dx: self.finishPoint.x - self.startPoint.x, dy: self.finishPoint.y - self.startPoint.y)
            let vec2 : CGVector = CGVector(dx: convertedRect.minX + convertedRect.width / 2 - self.startPoint.x, dy: convertedRect.minY + convertedRect.height / 2 - self.startPoint.y)
        
            
            let theta1 : Float = atan2f(Float(vec1.dy), Float(vec1.dx))
            let theta2 : Float = atan2f(Float(vec2.dy), Float(vec2.dx))
        
            
            let angle = Double(theta1 - theta2)
            let vec1length = sqrt(vec1.dx * vec1.dx + vec1.dy * vec1.dy)
            let vec2length = sqrt(vec2.dx * vec2.dx + vec2.dy * vec2.dy)
            let projection = cos(angle) * Double(vec2length)
            let percentage = projection / Double(vec1length)
            
            print(percentage * 100)
            
            if percentage >= 1 {
                let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            print("angle: %.1f°, ", angle / M_PI * 180)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // make sure the layer is the correct size
        self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }
    
    @IBAction func readyButtonClicked(_ sender: Any) {
        
        self.startPoint = initImage.center
        self.finishPoint = finishImage.center
        
        print(initImage.center)
        print(finishImage.center)
        
        //readyButton.removeFromSuperview()
        
    }
    
    @objc func drag(_ recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint(x:0, y:0), in: self.view)
    }
}
