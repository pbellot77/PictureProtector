//
//  ViewController.swift
//  PictureProtector
//
//  Created by Patrick Bellot on 8/30/17.
//  Copyright © 2017 Polestar Interactive LLC. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var imageView: UIImageView!
  
  var inputImage: UIImage?
  var detectedFaces = [(observation: VNFaceObservation, blur: Bool)]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importPhoto))
  }

  @objc func importPhoto() {
    let picker = UIImagePickerController()
    picker.allowsEditing = true
    picker.delegate = self
    present(picker, animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    // pull out the image that was selected
    guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
    
    // save it in our image view and property
    imageView.image = image
    inputImage = image
    
    // hide the image picker
    dismiss(animated: true) {
      
      // detect faces
      self.detectFaces()
    }
  }
  
  func detectFaces() {
    
    guard let inputImage = inputImage else { return }
    guard let ciImage = CIImage(image: inputImage) else { return }
    
    let request = VNDetectFaceRectanglesRequest { [unowned self] request, error in
      if let error = error {
        print(error.localizedDescription)
      } else {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        
        self.detectedFaces = Array(zip(observations, [Bool](repeating: false, count: observations.count)))
        self.addBlurRects()
      }
    }
    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    
    do {
      try handler.perform([request])
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func addBlurRects() {
    //remove any existing face rectangles
    imageView.subviews.forEach { $0.removeFromSuperview() }
    
    //find the size of the image inside the imageView
    let imageRect = imageView.contentClippingRect
    
    //loop over all the faces that were detected
    for (index, face) in detectedFaces.enumerated() {
      
      //pull out the face position
      let boundingBox = face.observation.boundingBox
      
      //calculate its size
      let size = CGSize(width: boundingBox.width * imageRect.width, height: boundingBox.height * imageRect.height)
      
      //calculate its position
      var origin = CGPoint(x: boundingBox.minX * imageRect.width, y: (1 - face.observation.boundingBox.minY) * imageRect.height - size.height)
      
      //offset the position based on the content clipping rect
      origin.y += imageRect.minY
      
      //place a UIView there
      let vw = UIView(frame: CGRect(origin: origin, size: size))
      
      //store its face number as its tag
      vw.tag = index
      
      //color its border red and add it
      vw.layer.borderColor = UIColor.red.cgColor
      vw.layer.borderWidth = 2
      imageView.addSubview(vw)
      
      let recognizer = UITapGestureRecognizer(target: self, action: #selector(faceTapped))
      vw.addGestureRecognizer(recognizer)
    }
  }
  
  // for device rotating in landscape mode
  override func viewDidLayoutSubviews() {
    addBlurRects()
  }
  
  func renderBlurredFaces() {
    guard let currentUIImage = inputImage else { return }
    guard let currentCGImage = currentUIImage.cgImage else { return }
    let currentCIImage = CIImage(cgImage: currentCGImage)
    
    let filter = CIFilter(name: "CIPixellate")
    filter?.setValue(currentCIImage, forKey: kCIInputImageKey)
    filter?.setValue(12, forKey: kCIInputImageKey)
    
    guard let outputImage = filter?.outputImage else { return }
    let blurredImage = UIImage(ciImage: outputImage)
    
    //prepare to render a new image at the full size we need
    let renderer = UIGraphicsImageRenderer(size: currentUIImage.size)
    
    //commence rendering
    let result = renderer.image { ctx in
      
      //draw the original image first
      currentUIImage.draw(at: .zero)
      
      //create an empty clipping path that will hold our faces
      let path = UIBezierPath()
      
      for face in detectedFaces {
        //if this face ought to be blurred...
        if face.blur {
          //calculate the position of this face in image coordinates
          let boundingBox = face.observation.boundingBox
          let size = CGSize(width: boundingBox.width * currentUIImage.size.width, height: boundingBox.height * currentUIImage.size.height)
          let origin = CGPoint(x: boundingBox.minY * currentUIImage.size.width, y: (1 - face.observation.boundingBox.minY) * currentUIImage.size.height - size.height)
          let rect = CGRect(origin: origin, size: size)
          
          //convert those coordinates to a path, and add it to our clipping path
          let miniPath = UIBezierPath(rect: rect)
          path.append(miniPath)
        }
      }
      //if our clipping path isn't empty, activate it now then draw the blurred image with that mask
      if !path.isEmpty {
        path.addClip()
        blurredImage.draw(at: .zero)
      }
    }
    //show the result in our image view
    imageView.image = result
  }
  
  @objc func faceTapped(_ sender: UITapGestureRecognizer) {
    guard let vw = sender.view else { return }
    detectedFaces[vw.tag].blur = !detectedFaces[vw.tag].blur
    renderBlurredFaces()
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
}// end of class

