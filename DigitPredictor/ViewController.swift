//
//  ViewController.swift
//  DigitPredictor
//
//  Created by Elmo on 2018-01-29.
//  Copyright © 2018 ECE1780. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController, CameraBufferDelegate {
    
    let model = DigitPredictionModel()
    
    var cameraBuffer: CameraBuffer!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var predictedDigitLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraBuffer = CameraBuffer()
        cameraBuffer.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func captured(image: UIImage) {
        imageView.image = image
        
        let h = image.size.height
        let w = image.size.width
        let cropRegion = CGRect(x: 0, y: (h-w)/2, width: w, height: w)
        let imageData = image.cgImage!.cropping(to: cropRegion)!
        
        let imageResized = UIImage(cgImage: imageData).imageWithSize(size: CGSize(width: 14, height: 14))
        
        let rgbs = imageResized.getRGBs()
        
        guard let input = try? MLMultiArray(shape: [1, 28, 28], dataType: .double) else {
            return
        }
        for y in 0..<28 {
            for x in 0..<28{
                let offset = (28*y + x) * 3
                let r = rgbs[offset]
                let g = rgbs[offset + 1]
                let b = rgbs[offset + 2]
                let pixelIntensity = 1.0 - (r + g + b) / 3
                
                let index = [NSNumber(value: 0), NSNumber(value: y), NSNumber(value: x)]
                input[index] = NSNumber(value: pixelIntensity)
            }
        }
        
        guard let digitProbabilities = try? model.prediction(image__0: input).prediction__0 else {
            print("Something went wrong predicting the output")
            return
        }

        var predictedDigit = 0
        var highestProbability = 0.0
        for i in 0..<10 {
            if digitProbabilities[i].doubleValue > highestProbability {
                highestProbability = digitProbabilities[i].doubleValue
                predictedDigit = i
            }
        }
        self.predictedDigitLabel.text = String(predictedDigit)
    }
}

extension UIImage
{
    func imageWithSize(size:CGSize) -> UIImage
    {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        
        //max - scaleAspectFill | min - scaleAspectFit
        let aspectRatio:CGFloat = max(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func getRGBs() -> [Double] {
        var result = [Double]()
        
        // First get the image into your data buffer
        guard let cgImage = self.cgImage else {
            print("CGContext creation failed")
            return []
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawdata = calloc(height*width*4, MemoryLayout<CUnsignedChar>.size)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: rawdata, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("CGContext creation failed")
            return result
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Now your rawData contains the image data in the RGBA8888 pixel format.
        var byteIndex = 0
        let count = cgImage.width * cgImage.height
        for _ in 0..<count {
            let red = CGFloat(rawdata!.load(fromByteOffset: byteIndex, as: UInt8.self)) / 255.0
            let green = CGFloat(rawdata!.load(fromByteOffset: byteIndex + 1, as: UInt8.self)) / 255.0
            let blue = CGFloat(rawdata!.load(fromByteOffset: byteIndex + 2, as: UInt8.self)) / 255.0
            byteIndex += bytesPerPixel
            
            result.append(Double(red))
            result.append(Double(blue))
            result.append(Double(green))
        }
        
        free(rawdata)
        
        return result
    }
}
