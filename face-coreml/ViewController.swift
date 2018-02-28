//
//  ViewController.swift
//  face-coreml
//
//  Created by Daniel Otero Cortes on 26/2/18.
//  Copyright © 2018 Daniel Otero Cortes. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!
    var selectedImage : UIImage = UIImage()
    
    lazy var request : VNDetectFaceLandmarksRequest = {
        let flRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            self?.processResults(results: results)
        }
        return flRequest
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadingView.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take picture", style: .default, handler: { _ in
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Use existing one", style: .default, handler: { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Use demo image", style: .default, handler: { _ in
            self.startProcessingImage(image: #imageLiteral(resourceName: "test.jpg"))
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startProcessingImage(image: UIImage) {
        self.selectedImage = image
        self.loadingView.isHidden = false
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global().async {
            try! handler.perform([self.request])
        }
    }
    
    func processResults(results: [VNFaceObservation]) {
        self.drawNormalizedRectsOverImage(rects: results.map {$0.boundingBox})
        let allLandmarks = results.flatMap {$0.landmarks}
        self.drawLandMarkRegion(regions:self.getEyes(landmarks: allLandmarks), color: .yellow)
        self.drawLandMarkRegion(regions:self.getMouths(landmarks: allLandmarks), color: .green)
    }
    
    func drawNormalizedRectsOverImage(rects: [CGRect], color: UIColor = UIColor.red) {
        drawOverImage(rects: rects.map {$0.toUIKitRect() * selectedImage.size})
    }

    func drawOverImage(rects: [CGRect], color: UIColor = UIColor.red) {
        let imageRect = CGRect(x: 0, y: 0, width: selectedImage.size.width, height: selectedImage.size.height)
        UIGraphicsBeginImageContext(selectedImage.size)
        self.selectedImage.draw(in: imageRect)
        rects.forEach { rect in
            let ctx = UIGraphicsGetCurrentContext()
            ctx?.addRect(rect)
            ctx?.setLineWidth(5)
            ctx?.setStrokeColor(color.cgColor)
            ctx?.drawPath(using: .stroke)
        }
        let imageResult = UIGraphicsGetImageFromCurrentImageContext()
        self.selectedImage = imageResult!
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            self.imageView.image = imageResult
        }
    }
    
    func drawLandMarkRegion(regions: [VNFaceLandmarkRegion2D], color: UIColor) {
        let rects = regions.flatMap {CGRect.boundingBox(points: $0.pointsInImage(imageSize: self.selectedImage.size))?.toUIKitRect(totalHeight: self.selectedImage.size.height)}
        drawOverImage(rects: rects, color:color)
    }
    
    func getEyes(landmarks: [VNFaceLandmarks2D]) -> [VNFaceLandmarkRegion2D] {
        var eyes = landmarks.flatMap {$0.leftEye}
        eyes.append(contentsOf: landmarks.flatMap {$0.rightEye})
        return eyes
    }
    
    func getMouths(landmarks: [VNFaceLandmarks2D]) -> [VNFaceLandmarkRegion2D] {
        return landmarks.flatMap {$0.outerLips}
    }
    
    // MARK - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        debugPrint(info)
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }

        startProcessingImage(image: image)
    }
}
