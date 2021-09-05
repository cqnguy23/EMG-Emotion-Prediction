//
//  PlotController.swift
//  Senior Design
//
//  Created by Tom Nguyen on 4/22/21.
//  Copyright © 2021 tomnguyen. All rights reserved.
//

import CorePlot
var plotDataOne = [Float32](repeating: 0.0, count: 980)
var plotDataTwo = [Float32](repeating: 0.0, count: 980)
var plotDataThree = [Float32](repeating: 0.0, count: 980)
var plotTimer : Timer?
extension ViewController: CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    func fireTimer(_ val: Float32, _ plotNum: Int) {
        let graph = self.graphView.hostedGraph
        let plotOne = graph?.plot(withIdentifier: "graphOne" as NSCopying)
        let plotTwo = graph?.plot(withIdentifier: "graphTwo" as NSCopying)
        let plotThree = graph?.plot(withIdentifier: "graphThree" as NSCopying)
        guard let plotSpace = graph?.defaultPlotSpace as? CPTXYPlotSpace else {
            return
        }
        if (self.currentIndexOne >= maxDataPoints && self.currentIndexTwo >= maxDataPoints && self.currentIndexThree >= maxDataPoints ) {
            let plotOneTemp = Array(plotDataOne[513...maxDataPoints-1])
            let plotTwoTemp = Array(plotDataTwo[513...maxDataPoints-1])
            let plotThreeTemp = Array(plotDataThree[513...maxDataPoints-1])
            
            createCSV([plotOneTemp, plotTwoTemp, plotThreeTemp])
            
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
        let title = "EMG Signals"
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

extension Numeric {
    var data: Data {
        var source = self
        // This will return 1 byte for 8-bit, 2 bytes for 16-bit, 4 bytes for 32-bit and 8 bytes for 64-bit binary integers. For floating point types it will return 4 bytes for single-precision, 8 bytes for double-precision and 16 bytes for extended precision.
        return .init(bytes: &source, count: MemoryLayout<Self>.size)
    }
}
extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    #else
    self = unsafeData.withUnsafeBytes {
      .init(UnsafeBufferPointer<Element>(
        start: $0,
        count: unsafeData.count / MemoryLayout<Element>.stride
      ))
    }
    #endif  // swift(>=5.0)
  }
}
