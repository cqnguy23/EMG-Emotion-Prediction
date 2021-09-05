//
//  ViewController.swift
//  Senior Design
//
//  Created by Tom Nguyen on 10/20/20.
//  Copyright © 2020 tomnguyen. All rights reserved.
//

import UIKit
import CoreBluetooth
import CorePlot
import TensorFlowLite




class ViewController: UIViewController {
    var inputData = Data()
    var centralManager: CBCentralManager!
    @IBOutlet weak var signalLabel: UILabel!
    @IBOutlet var graphView: CPTGraphHostingView!
    @IBOutlet var emotionLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var imageLabel: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var happyLabel: UILabel!
    @IBOutlet var sadLabel: UILabel!
    @IBOutlet var angryLabel: UILabel!
    var plotDataOne = [Float32](repeating: 0.0, count: 980)
    var plotDataTwo = [Float32](repeating: 0.0, count: 980)
    var plotDataThree = [Float32](repeating: 0.0, count: 980)
    var plotTimer : Timer?
    var timer: Timer?
    var emotion = "Nothing"
    var currentIndexOne: Int!
    var currentIndexTwo: Int!
    var currentIndexThree: Int!
    var timeDuration:Double = 0.1
    var maxDataPoints = 980
    var plotOne: CPTScatterPlot!
    var plotTwo: CPTScatterPlot!
    var plotThree: CPTScatterPlot!
    var fileName = "data.csv"
    var timeCount = 0
    var RSSIs = [NSNumber]()
    var data = NSMutableData()
    var writeData: String = ""
    var sensorPeripheral: CBPeripheral!
    var characteristicValue = [CBUUID: NSData]()
    var characteristics = [String : CBCharacteristic]()
    var modelPath: String!
    var interpreter: Interpreter?
  
    
    @objc func updateEmotion(_ val: String) {
        self.emotion = val
        DispatchQueue.main.async() {
            self.emotionLabel.text = val
        }
    }
    
    
    
  
  override func viewDidLoad() {
    super.viewDidLoad()
    timeLabel.layer.masksToBounds = true
    timeLabel.layer.cornerRadius = 8
    imageLabel.image = UIImage(named: "noemtion.png")
    emotionLabel.text = "Nothing"
    timeLabel.text = String(timeCount)
    centralManager = CBCentralManager(delegate: self, queue: nil)
    drawGraph()
    configureML()
    configureCSV()
    
    // Make the digits monospaces to avoid shifting when the numbers change

  }
    
    
    
    @IBAction func disconnect(sender: UIButton) {
        centralManager.cancelPeripheralConnection(sensorPeripheral)
    }
    
    @IBAction func reconnect(sender: UIButton) {
         self.centralManager?.scanForPeripherals(withServices: [BLEService_UUID], options: nil)
        print("Here")
    }
 
}




