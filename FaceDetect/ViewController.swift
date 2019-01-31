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

    /// Begin searching for faces rectangles and face landmarks.
    func performDetectionRequests() {
        let requests = [faceDetectRequest, faceLandmarksDetectRequest]
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }

    // MARK: Detections

    /// Draw a rectangle around the detected face.
    ///
    /// ⚠️ Must be executed on the main thread.
    ///
    /// - Parameters:
    ///   - request: A `VNDetectFaceRectanglesRequest` request.
    ///   - error: An error, if any were thrown by the `request`.
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
                let boundingBox = self.boundingBox(forRegionOfInterest: observation.boundingBox, inImageWithBounds: self.imageView.frame)

                let emojiLayer = CATextLayer()
                emojiLayer.frame = boundingBox
                emojiLayer.fontSize = 0.9 * boundingBox.height
                emojiLayer.alignmentMode = .center
//                emojiLayer.string = "💩"
                emojiLayer.borderColor = UIColor.blue.cgColor
                emojiLayer.borderWidth = 1

                self.drawLayer.addSublayer(emojiLayer)
            }
            CATransaction.commit()

            self.drawLayer.setNeedsDisplay()
        }
    }

    func handleFaceLandmarksDetection(forRequest request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNFaceObservation] else {
                assertionFailure("Invalid result type: \(String(describing: request.results))")
                return
            }

            CATransaction.begin()
            for observation in results {
                let imageSize = self.imageView.bounds.size
                print("Image size: \(imageSize)")
                let landmarks = observation.landmarks?.outerLips?.pointsInImage(imageSize: imageSize) ?? []
                print("Landmark  points: \(landmarks)")
                let shapeLayer = CAShapeLayer()
                shapeLayer.frame = self.imageView.frame
                self.drawPaths(of: landmarks, onLayer: shapeLayer)

                print("Draw Layer: \(self.drawLayer.bounds)")
                self.drawLayer.addSublayer(shapeLayer)
            }
            CATransaction.commit()
            self.drawLayer.setNeedsDisplay()
        }
    }

    func drawPaths(of points: [CGPoint], onLayer layer: CAShapeLayer) {
        layer.strokeColor = UIColor.blue.cgColor
        layer.lineWidth = 2
        let path = CGMutablePath()

        guard !points.isEmpty else {
            return
        }

        for (index, point) in points.enumerated() {
            guard index > 0 else {
                path.move(to: point)
                print("Moving to \(point)")
                continue
            }
            path.addLine(to: point)
            print("Adding line to \(point)")
        }

        layer.path = path
    }

    // MARK: Calculations

    /// Translates a rectangle in unit coordinate space to the coordinate space of the given image's bounds.
    ///
    /// - Parameters:
    ///   - roi: The "region of interest", a coordinate space with `x` and `y` values between `0.0`
    ///
    ///   - imageBounds:
    /// - Returns: A rectangle that's been translated from the unit coordinate space to the
    ///     `imageBounds` coordinate space.
    func boundingBox(forRegionOfInterest roi: CGRect, inImageWithBounds imageBounds: CGRect) -> CGRect {
        let observationHeight = roi.height * imageBounds.height
        let observationWidth = roi.width * imageBounds.width
        let observationCoordinateX = roi.origin.x * imageBounds.width
        let observationCoordinateY = imageBounds.height - (roi.origin.y * imageBounds.height) - observationHeight

        let rect = CGRect(x: observationCoordinateX, y: observationCoordinateY, width: observationWidth, height: observationHeight)
        return rect
    }
}

extension ViewController: CALayerDelegate {

}

