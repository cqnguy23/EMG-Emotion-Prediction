//
//  MLModel.swift
//  Senior Design
//
//  Created by Tom Nguyen on 4/22/21.
//  Copyright © 2021 tomnguyen. All rights reserved.
//

import TensorFlowLite

extension ViewController {
    func configureML() {
        modelPath = Bundle.main.path(forResource: "model", ofType: "tflite")
        if (modelPath == "") {
            print("Can't locate path")
            return
        }
        do {
            try interpreter = Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
        }
        catch {
            print(error)
        }
    }
    
    func inferenceML(_ data: Data){
        do {
            try self.interpreter?.copy(data, toInputAt: 0)
            try self.interpreter?.invoke()
            let outputTensor = try self.interpreter?.output(at: 0)
        
            let outputSize = outputTensor?.shape.dimensions.reduce(1, {x, y in x * y})
            let results: [Float]
            switch outputTensor!.dataType {
                case .uInt8:
                    guard let quantization = outputTensor?.quantizationParameters else {
                    print("No results returned because the quantization values for the output tensor are nil.")
                    return
                  }
                    let quantizedResults = [UInt8](outputTensor!.data)
                  results = quantizedResults.map {
                    quantization.scale * Float(Int($0) - quantization.zeroPoint)
                  }
                case .float32:
                  results = [Float32](unsafeData: outputTensor!.data) ?? []
                default:
                  print("Output tensor data type \(outputTensor!.dataType) is unsupported for this example app.")
                  return
                }

            guard let labelPath = Bundle.main.path(forResource: "labels", ofType: "txt") else { return }
            let fileContents = try String(contentsOfFile: labelPath)
            let labels = fileContents.components(separatedBy: "\n")

            if let max = results.max(), let index = results.firstIndex(of: max){
                DispatchQueue.main.async() {
                    if (index == 0) {
                        self.updateEmotion("Happy")
                        self.imageLabel.image = UIImage(named: "happy.png")
                    }
                    else if (index == 1) {
                        self.updateEmotion("Sad")
                        self.imageLabel.image = UIImage(named: "sad.png")
                    }
                    else if (index == 2) {
                        self.updateEmotion("Angry")
                        self.imageLabel.image = UIImage(named: "angry.png")
                    }
                }
            }
            
            for i in labels.indices {
                print("\(labels[i]): \(results[i])\n")
            }

            DispatchQueue.main.async() {
                self.happyLabel.text = "Happy: \(results[0])"
                self.sadLabel.text = "Sad: \(results[1])"
                self.angryLabel.text = "Angry: \(results[2])"
            }
        }
        catch {
            print(error)
        }
        return
    }
}
