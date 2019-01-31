//
//  ViewController.swift
//  ShirtHead
//
//  Created by Jeff Small on 1/29/19.
//  Copyright © 2019 One Medical. All rights reserved.
//

import CoreGraphics
import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    lazy var drawLayer: CALayer = {
        let layer = CALayer(layer: imageView.layer)
        layer.frame = imageView.bounds
        layer.backgroundColor = UIColor.clear.cgColor
        return layer
    }()

    var imageRequestHandler: VNImageRequestHandler!

    lazy var faceDetectRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaceDetection)
        return request
    }()

    lazy var faceLandmarksDetectRequest: VNDetectFaceLandmarksRequest = {
        let request = VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksDetection)
        return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.addSublayer(drawLayer)
        imageRequestHandler =  VNImageRequestHandler(cgImage: imageView.image!.cgImage!, options: [:])
        performDetectionRequests()
    }

    func performDetectionRequests() {
        let request = faceDetectRequest
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.imageRequestHandler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }

    func handleFaceDetection(forRequest request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNFaceObservation] else {
                if let error = error {
                    assertionFailure(error.localizedDescription)
                }
                return
            }

            CATransaction.begin()
            for observation in results {
                print("Image View Bounds: \(self.imageView.bounds)")
                print("Observation Bounds: \(observation.boundingBox)")

                let boundingBox = self.boundingBox(forRegionOfInterest: observation.boundingBox, inImageWithBounds: self.imageView.frame)

                let emojiLayer = CATextLayer()
                emojiLayer.frame = boundingBox
                emojiLayer.fontSize = 0.9 * boundingBox.height
                emojiLayer.alignmentMode = .center
                emojiLayer.borderColor = UIColor.blue.cgColor
                emojiLayer.borderWidth = 1

                self.drawLayer.addSublayer(emojiLayer)
            }
            CATransaction.commit()

            self.drawLayer.setNeedsDisplay()
        }
    }

    func boundingBox(forRegionOfInterest roi: CGRect, inImageWithBounds imageBounds: CGRect) -> CGRect {
        let observationHeight = roi.height * imageBounds.height
        let observationWidth = roi.width * imageBounds.width
        let observationCoordinateX = roi.origin.x * imageBounds.width
        let observationCoordinateY = imageBounds.height - (roi.origin.y * imageBounds.height) - observationHeight

        let rect = CGRect(x: observationCoordinateX, y: observationCoordinateY, width: observationWidth, height: observationHeight)
        print("Bounding box for ROI: \(rect)")
        return rect
    }

    func handleFaceLandmarksDetection(forRequest request: VNRequest, error: Error?) {

    }
}

