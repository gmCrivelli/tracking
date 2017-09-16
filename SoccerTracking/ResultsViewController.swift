//
//  ResultsViewController.swift
//  SoccerTracking
//
//  Created by Mauricio Lorenzetti on 16/09/17.
//  Copyright © 2017 Gustavo De Mello Crivelli. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var graphDistanceTempo: GraphView!
    @IBOutlet weak var graphVelocityTime: GraphView!
    @IBOutlet weak var graphVelocityDistance: GraphView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var graphLabel: UILabel!
    
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
        
        
        graphDistanceTempo.frame = (graphDistanceTempo.frame.offsetBy(dx: scrollView.contentSize.width, dy: 0))
        scrollView.addSubview(graphDistanceTempo)
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width + self.view.frame.width, height: (graphDistanceTempo.frame.height))
        
        graphVelocityTime.frame = (graphVelocityTime.frame.offsetBy(dx: scrollView.contentSize.width, dy: 0))
        scrollView.addSubview(graphVelocityTime)
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width + self.view.frame.width, height: ( graphVelocityTime.frame.height))
       
        
        
        graphVelocityDistance.frame = (graphVelocityDistance.frame.offsetBy(dx: scrollView.contentSize.width, dy: 0))
        scrollView.addSubview(graphVelocityDistance)
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width + self.view.frame.width, height: (graphVelocityDistance.frame.height))
        
        
        pageControl.layer.cornerRadius = 10
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        
        
        let page = floor(scrollView.contentOffset.x / self.view.frame.width)
        
        pageControl.currentPage = Int(page)
        if(Int(page) == 0) {
            graphLabel.text = "Distância x Tempo"
        }
        else if(Int(page) == 1)  {
            graphLabel.text = "Velocidade x Tempo"
        }
        else {
            graphLabel.text = "Velocidade x Distância"
        }
        
        
    }
    
    
}
