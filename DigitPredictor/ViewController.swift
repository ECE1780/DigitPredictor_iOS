//
//  ViewController.swift
//  DigitPredictor
//
//  Created by Elmo on 2018-01-29.
//  Copyright © 2018 ECE1780. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CameraBufferDelegate {
    
    let model = DigitPredictionModel()
    
    var cameraBuffer: CameraBuffer!
    
    @IBOutlet weak var imageView: UIImageView!
    
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
    }
}

