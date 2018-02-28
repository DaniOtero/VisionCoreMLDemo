//
//  ViewController.swift
//  face-coreml
//
//  Created by Daniel Otero Cortes on 26/2/18.
//  Copyright © 2018 Daniel Otero Cortes. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!
    var image = #imageLiteral(resourceName: "test.jpg")
    
    lazy var request : VNDetectFaceLandmarksRequest = {
        let flRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            self?.drawNormalizedRectsOverImage(rects: results.map {$0.boundingBox})
            let allLandmarks = results.flatMap {$0.landmarks}
            self?.drawLandMarkRegion(regions:self?.getEyes(landmarks: allLandmarks) ?? [], color: .yellow)
            self?.drawLandMarkRegion(regions:self?.getMouths(landmarks: allLandmarks) ?? [], color: .green)
        }
        return flRequest
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
        self.loadingView.isHidden = false
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global().async {
            //try! handler.perform([self.request])
            try! handler.perform([self.request])
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func drawNormalizedRectsOverImage(rects: [CGRect], color: UIColor = UIColor.red) {
        drawOverImage(rects: rects.map {$0.toUIKitRect() * image.size})
    }

    func drawOverImage(rects: [CGRect], color: UIColor = UIColor.red) {
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        UIGraphicsBeginImageContext(image.size)
        self.image.draw(in: imageRect)
        rects.forEach { rect in
            let ctx = UIGraphicsGetCurrentContext()
            ctx?.addRect(rect)
            ctx?.setLineWidth(5)
            ctx?.setStrokeColor(color.cgColor)
            ctx?.drawPath(using: .stroke)
        }
        let imageResult = UIGraphicsGetImageFromCurrentImageContext()
        self.image = imageResult!
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            self.imageView.image = imageResult
        }
    }
    
    func drawLandMarks(landmarks: VNFaceLandmarks2D?) {
        guard let landmarks = landmarks,let points = landmarks.leftEye?.pointsInImage(imageSize: self.image.size), let rect = CGRect.boundingBox(points: points) else {
            return
        }
        drawOverImage(rects: [rect.toUIKitRect(totalHeight: self.image.size.height)], color:.yellow)
    }
    
    func getEyes(landmarks: [VNFaceLandmarks2D]) -> [VNFaceLandmarkRegion2D] {
        var eyes = landmarks.flatMap {$0.leftEye}
        eyes.append(contentsOf: landmarks.flatMap {$0.rightEye})
        return eyes
    }
    
    func getMouths(landmarks: [VNFaceLandmarks2D]) -> [VNFaceLandmarkRegion2D] {
        return landmarks.flatMap {$0.outerLips}
    }
    
    func drawLandMarkRegion(regions: [VNFaceLandmarkRegion2D], color: UIColor) {
        let rects = regions.flatMap {CGRect.boundingBox(points: $0.pointsInImage(imageSize: self.image.size))?.toUIKitRect(totalHeight: self.image.size.height)}
        drawOverImage(rects: rects, color:color)
    }
}

extension CGRect {
    static func *(left: CGRect, right: CGSize) -> CGRect {
        let width = right.width
        let height = right.height
        return CGRect(x: left.origin.x * width, y: left.origin.y * height, width: left.size.width * width, height: left.size.height * height)
    }
    
    func toUIKitRect() -> CGRect {
        return self.toUIKitRect(totalHeight: 1)
    }
    
    func toUIKitRect(totalHeight: CGFloat) -> CGRect {
        return CGRect(x: self.origin.x, y: totalHeight - self.origin.y - self.size.height, width: self.size.width, height: self.size.height)
    }
    
    static func boundingBox(points: [CGPoint]) -> CGRect? {
        guard points.count > 2 else {
            return nil
        }
        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y
        points.forEach { point in
            minX = min(minX,point.x)
            maxX = max(maxX,point.x)
            minY = min(minY,point.y)
            maxY = max(maxY,point.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
