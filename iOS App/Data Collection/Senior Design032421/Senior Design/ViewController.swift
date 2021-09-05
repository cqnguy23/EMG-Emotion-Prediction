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




var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()
let BLEService_UUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let characteristicOne = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
let characteristicTwo = CBUUID(string: "af194280-866a-11eb-8dcd-0242ac130003")
let characteristicThree = CBUUID(string: "70def9d6-ac14-491e-9d9c-608e3b632a93")
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var signalLabel: UILabel!
    @IBOutlet var graphView: CPTGraphHostingView!
    @IBOutlet var emotionLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var imageLabel: UIImageView!
    var plotDataOne = [Double](repeating: 0.0, count: 700)
    var plotDataTwo = [Double](repeating: 0.0, count: 700)
    var plotDataThree = [Double](repeating: 0.0, count: 700)
    var plotTimer : Timer?
    var timer: Timer?
    var emotion = "Nothing"
    var currentIndexOne: Int!
    var currentIndexTwo: Int!
    var currentIndexThree: Int!
    var timeDuration:Double = 0.1
    var maxDataPoints = 700
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
    @objc func updateEmotion(_ val: String) {
        self.emotion = val
        DispatchQueue.main.async() {
            self.emotionLabel.text = val
        }
    }
    
    
    func configureCSV() {
        print("CSV Created")
        let csvString = "\("Emotion"),\("Sensor 1"),\("Sensor 2"),\("Sensor 3")\n\n"
        let fileManager = FileManager.default
                do {
                    let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
                    let fileURL = path.appendingPathComponent(fileName)
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("error creating file")
                }
    }
  var centralManager: CBCentralManager!
  override func viewDidLoad() {
    super.viewDidLoad()
    timeLabel.layer.masksToBounds = true
    timeLabel.layer.cornerRadius = 8
    imageLabel.image = UIImage(named: "noemtion.png")
    emotionLabel.text = "Nothing"
    timeLabel.text = String(timeCount)
    centralManager = CBCentralManager(delegate: self, queue: nil)
    drawGraph()
    
    configureCSV()
    
    // Make the digits monospaces to avoid shifting when the numbers change

  }
    var cnt : Int = 0
    func createCSV(_ val: [[Double]]) {
        
            var csvString = ""
            for i in (0...val[0].count - 1) {
                csvString = csvString.appending("\(emotion),\(String(describing: val[0][Int(i)])),\(String(describing: val[1][Int(i)])),\(String(describing: val[2][Int(i)]))\n")
            }
 
        
        
        let fileManager = FileManager.default
                do {
                    let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                    let fileURL = path.appendingPathComponent(fileName)
                    let file: FileHandle? = try FileHandle(forWritingTo:  fileURL)
                    
                            // assuming data contains contents to be written
                            let fileData = csvString.data(using: .utf8)
                            // seek to end of the file to append at the end of the file.
                            file?.seekToEndOfFile()
                            file?.write(fileData!)
                            file?.closeFile()
                        
                } catch {
                    print("error creating file \(error)")
                }
        
        
    }
    func fireTimer(_ val: Double, _ plotNum: Int) {
        let graph = self.graphView.hostedGraph
        let plotOne = graph?.plot(withIdentifier: "graphOne" as NSCopying)
        let plotTwo = graph?.plot(withIdentifier: "graphTwo" as NSCopying)
        let plotThree = graph?.plot(withIdentifier: "graphThree" as NSCopying)
        guard let plotSpace = graph?.defaultPlotSpace as? CPTXYPlotSpace else {
            return
        }
        if (self.currentIndexOne >= maxDataPoints && self.currentIndexTwo >= maxDataPoints && self.currentIndexThree >= maxDataPoints ) {
            var arr = [plotDataOne, plotDataTwo, plotDataThree]
            createCSV(arr)
            
            graph?.reloadData()
            plotOne?.reloadData()
            plotTwo?.reloadData()
            plotThree?.reloadData()
            self.currentIndexOne = 0
            self.currentIndexTwo = 0
            self.currentIndexThree = 0
            self.plotDataOne.removeAll()
            self.plotDataTwo.removeAll()
            self.plotDataThree.removeAll()
        }
        
        else {
            
            if (plotNum == 1) {
                self.currentIndexOne += 1;
                let pointOne = val
                self.plotDataOne.append(pointOne)
                plotOne?.insertData(at: UInt(self.plotDataOne.count-1), numberOfRecords: 1)
            }

            else if (plotNum == 2) {
                self.currentIndexTwo += 1;
                let pointTwo = val
                    self.plotDataTwo.append(pointTwo)
                    plotTwo?.insertData(at: UInt(self.plotDataTwo.count-1), numberOfRecords: 1)
            }
            else if (plotNum == 3) {
                self.currentIndexThree += 1;
                let pointThree = val
                    self.plotDataThree.append(pointThree)
                    plotThree?.insertData(at: UInt(self.plotDataThree.count-1), numberOfRecords: 1)
            }
        }
        
    }
    
    func drawGraph() {
        configureGraphView()
        configureGraphAxis()
        configurePlotOne()
        configurePlotTwo()
        configurePlotThree()
    }
    
    func configureGraphView() {
        graphView.allowPinchScaling = false
        self.plotDataOne.removeAll()
        self.plotDataTwo.removeAll()
        self.plotDataThree.removeAll()
        self.currentIndexOne = 0
        self.currentIndexTwo = 0
        self.currentIndexThree = 0
        
    }

    func configureGraphAxis() {
        //Configure graph
        let graph = CPTXYGraph(frame: graphView.bounds)
        graph.plotAreaFrame?.masksToBorder = false
        graphView.hostedGraph = graph
        graph.backgroundColor = UIColor.black.cgColor
        graph.paddingBottom = 50.0
        graph.paddingLeft = 50.0
        graph.paddingTop = 30.0
        graph.paddingRight = 15.0
        
        //Style for graph title
        let titleStyle = CPTMutableTextStyle()
        titleStyle.color = CPTColor.white()
        titleStyle.fontName = "HelveticaNeue-Bold"
        titleStyle.fontSize = 20.0
        titleStyle.textAlignment = .center
        graph.titleTextStyle = titleStyle

        //Set graph title
        let title = "Senior Project"
        graph.title = title
        graph.titlePlotAreaFrameAnchor = .top
        graph.titleDisplacement = CGPoint(x: 0.0, y: 0.0)
        let axisSet = graph.axisSet as! CPTXYAxisSet
        
        let axisTextStyle = CPTMutableTextStyle()
        axisTextStyle.color = CPTColor.white()
        axisTextStyle.fontName = "HelveticaNeue-Bold"
        axisTextStyle.fontSize = 10.0
        axisTextStyle.textAlignment = .center
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineColor = CPTColor.white()
        lineStyle.lineWidth = 5
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineColor = CPTColor.gray()
        gridLineStyle.lineWidth = 0.5
       
        
        if let x = axisSet.xAxis {
            
            x.majorIntervalLength   = 200
            x.minorTicksPerInterval = 5
            //x.axisTitle = CPTAxisTitle(text: "Time[ms]", textStyle: axisTextStyle)
            //x.labelTextStyle = axisTextStyle
            x.minorGridLineStyle = gridLineStyle
            x.axisLineStyle = lineStyle
            x.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            x.delegate = self
        }

        if let y = axisSet.yAxis {
            y.majorIntervalLength   = 1
            y.axisTitle = CPTAxisTitle(text: "EMG Signals [V]", textStyle: axisTextStyle)
            y.minorTicksPerInterval = 5
            y.minorGridLineStyle = gridLineStyle
            y.labelTextStyle = axisTextStyle
            y.alternatingBandFills = [CPTFill(color: CPTColor.init(componentRed: 255, green: 255, blue: 255, alpha: 0.03)),CPTFill(color: CPTColor.black())]
            y.axisLineStyle = lineStyle
            y.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            y.delegate = self
        }

        // Set plot space
        let xMin = 0.0
        let xMax = 800.0
        let yMin = -2.0
        let yMax = 2.0
        guard let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return }
        plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
    }
    
    func configurePlotOne(){
        plotOne = CPTScatterPlot()
        let plotLineStile = CPTMutableLineStyle()
        plotLineStile.lineJoin = .round
        plotLineStile.lineCap = .round
        plotLineStile.lineWidth = 2
        plotLineStile.lineColor = CPTColor.green()
        plotOne.dataLineStyle = plotLineStile
        plotOne.curvedInterpolationOption = .catmullCustomAlpha
        plotOne.interpolation = .curved
        plotOne.identifier = "graphOne" as NSCoding & NSCopying & NSObjectProtocol
        guard let graph = graphView.hostedGraph else { return }
        plotOne.dataSource = (self as CPTPlotDataSource)
        plotOne.delegate = (self as CALayerDelegate)
        graph.add(plotOne, to: graph.defaultPlotSpace)
      }
    
    func configurePlotTwo(){
        plotTwo = CPTScatterPlot()
        let plotLineStile = CPTMutableLineStyle()
        plotLineStile.lineJoin = .round
        plotLineStile.lineCap = .round
        plotLineStile.lineWidth = 2
        plotLineStile.lineColor = CPTColor.blue()
        plotTwo.dataLineStyle = plotLineStile
        plotTwo.curvedInterpolationOption = .catmullCustomAlpha
        plotTwo.interpolation = .curved
        plotTwo.identifier = "graphTwo" as NSCoding & NSCopying & NSObjectProtocol
        guard let graph = graphView.hostedGraph else { return }
        plotTwo.dataSource = (self as CPTPlotDataSource)
        plotTwo.delegate = (self as CALayerDelegate)
        graph.add(plotTwo, to: graph.defaultPlotSpace)
      }
    
    func configurePlotThree(){
        plotThree = CPTScatterPlot()
        let plotLineStile = CPTMutableLineStyle()
        plotLineStile.lineJoin = .round
        plotLineStile.lineCap = .round
        plotLineStile.lineWidth = 2
        plotLineStile.lineColor = CPTColor.red()
        plotThree?.dataLineStyle = plotLineStile
        plotThree?.curvedInterpolationOption = .catmullCustomAlpha
        plotThree?.interpolation = .curved
        plotThree?.identifier = "graphThree" as NSCoding & NSCopying & NSObjectProtocol
        guard let graph = graphView.hostedGraph else { return }
        plotThree?.dataSource = (self as CPTPlotDataSource)
        plotThree?.delegate = (self as CALayerDelegate)
        graph.add(plotThree, to: graph.defaultPlotSpace)
      }

    
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      print("State is unknown")
    case .resetting:
      print("State is resetting")
    case .unsupported:
      print("State is unsupported")
    case .unauthorized:
      print("State is unauthorized")
    case .poweredOff:
      print("State is poweredOff")
      
    case .poweredOn:
      print("State is poweredOn")
      startScan()
    }
  }
  func startScan() {
    print("Scanning...")
    self.timer?.invalidate()
    centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    //Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
  }
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
      
    print(peripheral)
    sensorPeripheral = peripheral
    centralManager.stopScan()
    centralManager.connect(sensorPeripheral)
    sensorPeripheral.delegate = self
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to Sensor!")
    sensorPeripheral.discoverServices(nil)
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        self.timeCount += 1
        DispatchQueue.main.async() {
            self.timeLabel.text = String(self.timeCount)
        }
    }
    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 12.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 14.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 21.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 23.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 41.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 44.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 54.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 57.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 67.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 70.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 80.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "noemtion.png")
    }
    Timer.scheduledTimer(withTimeInterval: 83.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 93.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 96.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 106.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 109.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 119.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "noemtion.png")
    }
    Timer.scheduledTimer(withTimeInterval: 123.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 133.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 136.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 146.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 149.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 159.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "noemtion.png")
    }
    Timer.scheduledTimer(withTimeInterval: 162.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 172.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 175.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 185.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 188.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 198.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "noemtion.png")
    }
    Timer.scheduledTimer(withTimeInterval: 201.0, repeats: false) { timer in
        self.updateEmotion("Happy")
        self.imageLabel.image = UIImage(named: "happy.png")
    }
    Timer.scheduledTimer(withTimeInterval: 211.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 214.0, repeats: false) { timer in
        self.updateEmotion("Sad")
        self.imageLabel.image = UIImage(named: "sad.png")
    }
    Timer.scheduledTimer(withTimeInterval: 224.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 227.0, repeats: false) { timer in
        self.updateEmotion("Angry")
        self.imageLabel.image = UIImage(named: "angry.png")
    }
    Timer.scheduledTimer(withTimeInterval: 237.0, repeats: false) { timer in
        self.updateEmotion("Nothing")
        self.imageLabel.image = UIImage(named: "noemtion.png")
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else {
      return
    }
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
    
}
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else {
      return
    }
    for characteristic in characteristics {

            //print("\(characteristic.uuid): properties contains .notify")
            if characteristic.uuid == characteristicOne {
            peripheral.setNotifyValue(true, for: characteristic as CBCharacteristic)
          }
            if characteristic.uuid == characteristicTwo {

            peripheral.setNotifyValue(true, for: characteristic as CBCharacteristic)
          }
            if characteristic.uuid == characteristicThree {
            peripheral.setNotifyValue(true, for: characteristic as CBCharacteristic)
          }
        print(characteristic)
      }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let characteristicData = characteristic.value {
      let byteArray = [UInt8](characteristicData)
        for i in (0...5) {
            print(byteArray[i])
        }
        var val1 : Int = 0
        var val2 : Int = 0
        var val3 : Int = 0
        //let temp = Double(value)
        
            for i in (0...1) {
                val1 = val1 << 8
                val1 = val1 | Int(byteArray[i])
            }
            //var temp = Double(val1)
            let temp1 = (Double(val1)-2047.5)/2047.5
            self.fireTimer(temp1, 1)
            NSLog("Sensor 1: " + String(temp1))
            
            for i in (2...3) {
                val2 = val2 << 8
                val2 = val2 | Int(byteArray[i])
            }
            let temp2 = (Double(val2)-2047.5)/2047.5
            //let temp = (Double(val1)-2047.5)/2047.5
            self.fireTimer(temp2, 2)
            NSLog("Sensor 2: " + String(temp2))
            
            for i in (4...5) {
                val3 = val3 << 8
                val3 = val3 | Int(byteArray[i])
            }
            let temp3 = (Double(val3)-2047.5)/2047.5
            //let temp = (Double(val1)-2047.5)/2047.5
            self.fireTimer(temp3, 3)
            NSLog("Sensor 3: " + String(temp3))
        
            
        /*
         DispatchQueue.main.async() {
        self.signalLabel.text = String(temp)
      }
 */
    
        

    }
    
}
  
  @objc func cancelScan() {
    centralManager?.stopScan()
    print("Scan Stopped")
  }
}


extension ViewController: CPTScatterPlotDataSource, CPTScatterPlotDelegate {
   
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        if (plot.identifier as! String == "graphOne") {
            return UInt(self.plotDataOne.count)
        }
        if (plot.identifier as! String == "graphTwo") {
            return UInt(self.plotDataTwo.count)
        }
        if (plot.identifier as! String == "graphThree") {
            return UInt(self.plotDataThree.count)
        }
        return 0
    }
    
    func number(for plot: CPTPlot, field : UInt, record : UInt) -> Any? {
        switch CPTScatterPlotField(rawValue: Int(field))! {
        case .X:
            if (plot.identifier as! String == "graphOne")
            {
                return NSNumber(value: Int(record)+self.currentIndexOne - self.plotDataOne.count)
            }
            if (plot.identifier as! String == "graphTwo")
            {
                return NSNumber(value: Int(record)+self.currentIndexTwo - self.plotDataTwo.count)
            }
            if (plot.identifier as! String == "graphThree")
            {
                return NSNumber(value: Int(record)+self.currentIndexThree - self.plotDataThree.count)
            }
            return 0
        case .Y:
            if (plot.identifier as! String == "graphOne") {
                return self.plotDataOne[Int(record)] as NSNumber
            }
            if (plot.identifier as! String == "graphTwo") {
                return self.plotDataTwo[Int(record)] as NSNumber
            }
            if (plot.identifier as! String == "graphThree") {
                return self.plotDataThree[Int(record)] as NSNumber
            }
            return 0
        default:
            return 0
        }
    }
}

