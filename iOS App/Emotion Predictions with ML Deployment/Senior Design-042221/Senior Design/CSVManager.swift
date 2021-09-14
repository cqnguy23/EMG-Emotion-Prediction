//
//  CSVManager.swift
//  Senior Design
//
//  Created by Tom Nguyen on 4/22/21.
//  Copyright © 2021 tomnguyen. All rights reserved.
//

import Foundation

extension ViewController {
    func configureCSV() {
        
        print("CSV Created")
        let csvString = "\("Sensor 1"),\("Sensor 2"),\("Sensor 3"),\("Emotion")\n\n"
        let fileManager = FileManager.default
                do {
                    let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
                    let fileURL = path.appendingPathComponent(fileName)
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("error creating file")
                }
    }
    
    func createCSV(_ val: [[Float32]]) {
            var csvString = ""
            for i in (0...val[0].count - 1) {
                csvString = csvString.appending("\(String(describing: val[0][Int(i)])) ,\(String(describing: val[1][Int(i)])),\(String(describing: val[2][Int(i)])), \(emotion)\n")
            }
        let fileManager = FileManager.default
                do {
                    let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
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
}
