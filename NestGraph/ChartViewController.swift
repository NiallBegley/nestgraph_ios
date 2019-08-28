//
//  ChartTableViewController.swift
//  NestGraph
//
//  Created by Niall on 8/12/19.
//  Copyright © 2019 Niall. All rights reserved.
//

import UIKit
import CoreData
import Charts

public class DateValueFormatter: NSObject, IAxisValueFormatter {
    private let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateFormatter.dateFormat = "h:mm a"
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}

class ChartViewController: UIViewController {

    @IBOutlet var chartView: LineChartView!
    lazy var device : Device = Device()
    lazy var persistentContainer : NSPersistentContainer = NSPersistentContainer.init()
    var recordController : RecordController?
    
    @objc func canRotate() -> Void {}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = device.name
        recordController = RecordController.init(container: persistentContainer)
        
        
        chartView.chartDescription?.enabled = false
        
        chartView.dragEnabled = false
//        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        chartView.highlightPerDragEnabled = true
        
        chartView.backgroundColor = .white
        
        chartView.legend.enabled = true
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottomInside
        xAxis.labelFont = .systemFont(ofSize: 8, weight: .light)
        xAxis.labelTextColor = UIColor.flatGrayDark
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 3600
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        leftAxis.granularity = 5
        
        leftAxis.labelTextColor = UIColor.flatGrayDark
        
        
        chartView.rightAxis.enabled = false
        chartView.legend.form = .line

        chartView.animate(xAxisDuration: 2.5)
        
        let today = Calendar.current
        guard let pastDate = today.date(byAdding: .hour, value: -24, to: Date(), wrappingComponents: false) else { return }
        
        guard let records : [Record] = recordController?.allRecords(forDevice: device, between: pastDate, Date()) else {return}
        
        var maximum : Int = -99999
        var minimum : Int = 99999
        
        let internalData = records.map {
            (record) -> ChartDataEntry in
            let y = record.internal_temp
            maximum = max(maximum, y)
            minimum = min(minimum, y)
            return ChartDataEntry(x: record.created_at?.timeIntervalSince1970 ?? 0, y: Double(y))
        }
        
        let externalData = records.map {
            (record) -> ChartDataEntry in
            let y = record.external_temp
            maximum = max(maximum, Int(y))
            minimum = min(minimum, Int(y))
            return ChartDataEntry(x: record.created_at?.timeIntervalSince1970 ?? 0, y: Double(y))
        }
        
        let externalHumidity = records.map {
            (record) -> ChartDataEntry in
            let y = record.external_humidity
            maximum = max(maximum, y)
            minimum = min(minimum, y)
            return ChartDataEntry(x: record.created_at?.timeIntervalSince1970 ?? 0, y: Double(y))
        }
        
        let internalHumidity = records.map {
            (record) -> ChartDataEntry in
            let y = record.humidity
            maximum = max(maximum, y)
            minimum = min(minimum, y)
            return ChartDataEntry(x: record.created_at?.timeIntervalSince1970 ?? 0, y: Double(y))
        }
        
        
        leftAxis.axisMinimum = Double(minimum)
        leftAxis.axisMaximum = Double(maximum)
        
        
        let set1 = LineChartDataSet(entries: internalData, label: "Internet Temperature")
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        set1.lineWidth = 1.5
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        set1.fillAlpha = 0.26
        set1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        
        
        let set2 = LineChartDataSet(entries: externalData, label: "External Temperature")
        set2.axisDependency = .left
        set2.setColor(UIColor.flatRed)
        set2.lineWidth = 1.5
        set2.drawCirclesEnabled = false
        set2.drawValuesEnabled = false
        set2.fillAlpha = 0.26
        set2.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set2.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set2.drawCircleHoleEnabled = false
        
        let set3 = LineChartDataSet(entries: externalHumidity, label: "External Humidity")
        set3.axisDependency = .left
        set3.setColor(UIColor.flatGreen)
        set3.lineWidth = 1.5
        set3.drawCirclesEnabled = false
        set3.drawValuesEnabled = false
        set3.fillAlpha = 0.26
        set3.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set3.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set3.drawCircleHoleEnabled = false
        
        let set4 = LineChartDataSet(entries: internalHumidity, label: "Internal Humidity")
        set4.axisDependency = .left
        set4.setColor(UIColor.flatYellow)
        set4.lineWidth = 1.5
        set4.drawCirclesEnabled = false
        set4.drawValuesEnabled = false
        set4.fillAlpha = 0.26
        set4.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set4.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set4.drawCircleHoleEnabled = false
        
        let data = LineChartData(dataSets: [set1, set2, set3, set4])
        
        chartView.data = data
    
        
        let lowestInt = recordController?.highestInternalTemp(forDevice: device)
        
//        chartView.highlightValue(x: lowestInt?.created_at?.timeIntervalSince1970 ?? 0, y: Double(lowestInt?.internal_temp ?? 0), dataSetIndex: 0)
    }


}
