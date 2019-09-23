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

enum ChartDisplayOptions {
    case highest
    case lowest
}

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
        chartView.pinchZoomEnabled = false
        chartView.highlightPerDragEnabled = true
        chartView.backgroundColor = .white
        chartView.legend.enabled = true
        chartView.doubleTapToZoomEnabled = false
        
        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottomInside
        xAxis.labelFont = .systemFont(ofSize: 8, weight: .light)
        xAxis.labelTextColor = UIColor.flatGrayDark()
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
        leftAxis.labelTextColor = UIColor.flatGrayDark()
        
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
        
        let targetTemp = records.map {
            (record) -> ChartDataEntry in
            let y = record.target_temp
            maximum = max(maximum, y)
            if y != 0 {
                minimum = min(minimum, y)
            }
            return ChartDataEntry(x: record.created_at?.timeIntervalSince1970 ?? 0, y: Double(y))
        }
        
        leftAxis.axisMinimum = Double(minimum)
        leftAxis.axisMaximum = Double(maximum)
        
        let set1 = createSet(withLabel: "Internal Temperature", UIColor.flatSkyBlue(), internalData)
        let set2 = createSet(withLabel: "External Temperature", UIColor.flatRed(), externalData)
        let set3 = createSet(withLabel: "External Humidity", UIColor.flatGreen(), externalHumidity)
        let set4 = createSet(withLabel: "Internal Humidity", UIColor.flatYellow(), internalHumidity)
        let set5 = createSet(withLabel: "Target Temp", UIColor.flatPowderBlue(), targetTemp)
        
        let data = LineChartData(dataSets: [set1, set2, set3, set4, set5])
        
        chartView.data = data
        
        selectedDisplayOption(.lowest)
    
    }

    func createSet(withLabel label: String, _ color: UIColor, _ data: [ChartDataEntry]) -> LineChartDataSet {
        let set = LineChartDataSet(entries: data, label: label)
        set.axisDependency = .left
        set.setColor(color)
        set.lineWidth = 1.5
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        set.fillAlpha = 0.26
        set.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set.drawCircleHoleEnabled = false
        set.highlightEnabled = true
        
        return set
    }
    
    
    // MARK: - ChartDisplay
    @IBAction func buttonClickedDisplay(_ sender: Any) {
        
        let alert = UIAlertController.init(title: "Display Options", message: "Select what values you would like to highlight", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction.init(title: "Lowest Temperatures", style: .default, handler: {(alert: UIAlertAction) in
            self.selectedDisplayOption(.lowest)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Highest Temperatures", style: .default, handler: {(alert: UIAlertAction) in
            self.selectedDisplayOption(.highest)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func selectedDisplayOption(_ option: ChartDisplayOptions) {
        
        var highlights : [Highlight]
        
        switch option {
            case .highest:
                guard let highestInt = recordController?.highestInternalTemp(forDevice: device),
                    let highestExt = recordController?.highestExternalTemp(forDevice: device),
                    let highestIntDate = highestInt.created_at,
                    let highestExtDate = highestExt.created_at else { return }
               
                highlights = [Highlight.init(x: highestIntDate.timeIntervalSince1970, y: Double(highestInt.internal_temp), dataSetIndex: 0),
                                  Highlight.init(x: highestExtDate.timeIntervalSince1970, y: Double(highestExt.external_temp), dataSetIndex: 1)]
                
                break;
            case .lowest:
                guard let lowestInt = recordController?.lowestInternalTemp(forDevice: device),
                    let lowestExt = recordController?.lowestExternalTemp(forDevice: device),
                    let lowIntDate = lowestInt.created_at,
                    let lowExtDate = lowestExt.created_at else { return }
                
                highlights = [Highlight.init(x: lowIntDate.timeIntervalSince1970, y: Double(lowestInt.internal_temp), dataSetIndex: 0),
                              Highlight.init(x: lowExtDate.timeIntervalSince1970, y: Double(lowestExt.external_temp), dataSetIndex: 1)]
                
                break;
            
        }
        
        chartView.highlightValues(highlights)
        
    }
}
