//
//  BluetoothController.swift
//  Senior Design
//
//  Created by Tom Nguyen on 4/22/21.
//  Copyright © 2021 tomnguyen. All rights reserved.
//

import CoreBluetooth

var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()
let BLEService_UUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let characteristicOne = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
let characteristicTwo = CBUUID(string: "af194280-866a-11eb-8dcd-0242ac130003")
let characteristicThree = CBUUID(string: "70def9d6-ac14-491e-9d9c-608e3b632a93")
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
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
      DispatchQueue.main.async() {
          self.statusLabel.text = "Scanning"
      }
      
      self.timer?.invalidate()
        self.centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
      //Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
      print(peripheral)
      sensorPeripheral = peripheral
        self.centralManager.stopScan()
        self.centralManager.connect(sensorPeripheral)
      sensorPeripheral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
      DispatchQueue.main.async() {
          self.statusLabel.text = "Connected to Sensor"
      }
      sensorPeripheral.discoverServices(nil)
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
          self.timeCount += 1
          DispatchQueue.main.async() {
              self.timeLabel.text = String(self.timeCount)
          }
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
      func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.centralManager.cancelPeripheralConnection(peripheral)
          DispatchQueue.main.async() {
              self.statusLabel.text = "Disconnected"
          }
          print(error ?? nil)
      }
    
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let characteristicData = characteristic.value {
      let byteArray = [UInt8](characteristicData)
        for i in (0...5) {
            //print(byteArray[i])
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
        var temp1 = (Float32(val1)-2047.5)/2047.5
            
            //NSLog("Sensor 1: " + String(temp1))
            
            for i in (2...3) {
                val2 = val2 << 8
                val2 = val2 | Int(byteArray[i])
            }
        var temp2 = (Float32(val2)-2047.5)/2047.5

            for i in (4...5) {
                val3 = val3 << 8
                val3 = val3 | Int(byteArray[i])
            }
        var temp3 = (Float32(val3)-2047.5)/2047.5
            //let temp = (Double(val1)-2047.5)/2047.5
            
            //NSLog("Sensor 3: " + String(temp3))
        let elemSize = MemoryLayout<Float32>.size
        var bytes =  [UInt8](repeating: 0, count: elemSize)
        if (inputData.count == 6144) {
            inferenceML(inputData)
            inputData.removeFirst(600)
        }
        memcpy(&bytes, &temp1, elemSize)
        inputData.append(&bytes, count: elemSize)
        
        memcpy(&bytes, &temp2, elemSize)
        inputData.append(&bytes, count: elemSize)
        
        memcpy(&bytes, &temp3, elemSize)
        inputData.append(&bytes, count: elemSize)
        
        self.fireTimer(temp1, 1)
        self.fireTimer(temp2, 2)
        self.fireTimer(temp3, 3)
        /*
         DispatchQueue.main.async() {
        self.signalLabel.text = String(temp)
      }
 */
    
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
}
