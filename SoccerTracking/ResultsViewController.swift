//
//  ResultsViewController.swift
//  SoccerTracking
//
//  Created by Mauricio Lorenzetti on 16/09/17.
//  Copyright © 2017 Gustavo De Mello Crivelli. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {
    
    @IBOutlet weak var graphDistanceTempo: GraphView!
    @IBOutlet weak var graphVelocityTime: GraphView!
    @IBOutlet weak var graphVelocityDistance: GraphView!
    
    var distanceTimeData:[(Double, Double)] = []
    var velocityTimeData:[(Double, Double)] = []
    var velocityDistanceData:[(Double, Double)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createVelocityTimeData()
        createVelocityDistanceData()
        
        print(velocityDistanceData, distanceTimeData, velocityTimeData)
        
        graphVelocityTime.graphPoints = velocityTimeData
        graphDistanceTempo.graphPoints = distanceTimeData
        graphVelocityDistance.graphPoints = velocityDistanceData
        
        graphVelocityDistance.setNeedsDisplay()
        graphDistanceTempo.setNeedsDisplay()
        graphVelocityTime.setNeedsDisplay()
    }
    
    func createVelocityTimeData() {
        velocityTimeData.append((0,0))
        
        for i in 0..<(distanceTimeData.count-1) {
            let newVelocity = (distanceTimeData[i+1].0 - distanceTimeData[i].0)/(distanceTimeData[i+1].1 - distanceTimeData[i].1)
            let newElement = (newVelocity,distanceTimeData[i+1].1)
            velocityTimeData.append(newElement)
        }
    }
    
    func createVelocityDistanceData() {
        
        for i in 0..<distanceTimeData.count {
            let newElement = (velocityTimeData[i].0,distanceTimeData[i].0)
            velocityDistanceData.append(newElement)
        }
    }
}
