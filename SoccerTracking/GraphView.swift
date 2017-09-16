//
//  GraphView.swift
//  SoccerTracking
//
//  Created by Mauricio Lorenzetti on 16/09/17.
//  Copyright © 2017 Gustavo De Mello Crivelli. All rights reserved.
//

import UIKit

class GraphView: UIView {
    
    @IBInspectable var startColor: UIColor = .red
    @IBInspectable var endColor: UIColor = .green
    
    var rawData:[(Double,Double)] = [(0.0,0.0),(10.0,3.0),(20.0,5.0),(30.0,6.0),(50.0,7.5)]
    var graphPoints:[(Double,Double)] = [(0.0,0.0),(10.0,3.0),(20.0,5.0),(30.0,6.0),(50.0,7.5)]
    
    private struct Constants {
        static let cornerRadiusSize = CGSize(width: 8.0, height: 8.0)
        static let margin: CGFloat = 20.0
        static let topBorder: CGFloat = 60
        static let bottomBorder: CGFloat = 50
        static let colorAlpha: CGFloat = 0.3
        static let circleDiameter: CGFloat = 5.0
    }

    override func draw(_ rect: CGRect) {
        
        let width = rect.width
        let height = rect.height
        
        //This path makes graphs borders round
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: .allCorners,
                                cornerRadii: Constants.cornerRadiusSize)
        path.addClip()
        
        //draws gradient behind graph
        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.cgColor, endColor.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: colors as CFArray,
                                  locations: colorLocations)!
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x: 0, y: bounds.height)
        context?.drawLinearGradient(gradient,
                                    start: startPoint,
                                    end: endPoint,
                                    options: [])
        
        //calculate x point
        let margin = Constants.margin
        let graphWidth = width - margin * 2 - 4
        var maxX:Double = 0.0
        for p in graphPoints {
            if p.1 > maxX {
                maxX = p.1
            }
        }
        let columnXPoint = { (rawX: Double) -> CGFloat in
            //Calculate the x value of the point on the graph
            return CGFloat(rawX / maxX) * graphWidth + margin + 2
        }
        
        //calculate y point
        let topBorder = Constants.topBorder
        let bottomBorder = Constants.bottomBorder
        let graphHeight = height - topBorder - bottomBorder
        let maxY = (graphPoints.last as (Double,Double)!).1
        
        let columnYPoint = { (graphPoint: Double) -> CGFloat in
            let y = CGFloat(graphPoint) / CGFloat(maxY) * graphHeight
            return graphHeight + topBorder - y // Flip the graph
        }
        
        //draw the line graph
        UIColor.white.setFill()
        UIColor.white.setStroke()
        
        let graphPath = UIBezierPath()
        
        graphPath.move(to: CGPoint(x: columnXPoint(graphPoints[0].1), y: columnYPoint(graphPoints[0].0)))
        
        for p in graphPoints {
            let nextPoint = CGPoint(x:columnXPoint(p.1), y:columnYPoint(p.0))
            graphPath.addLine(to: nextPoint)
        }
        
        //Create the clipping path for the graph gradient
        
        //1 - save the state of the context (commented out for now)
        context?.saveGState()
        
        //2 - make a copy of the path
        let clippingPath = graphPath.copy() as! UIBezierPath
        
        //3 - add lines to the copied path to complete the clip area
        clippingPath.addLine(to: CGPoint(x:columnXPoint(Double(graphPoints.count - 1)), y:height))
        clippingPath.addLine(to: CGPoint(x:columnXPoint(0), y:height))
        clippingPath.close()
        
        //4 - add the clipping path to the context
        clippingPath.addClip()
        
        //5 - gradient
        let highestYPoint = columnYPoint(maxY)
        let graphStartPoint = CGPoint(x: margin, y: highestYPoint)
        let graphEndPoint = CGPoint(x: margin, y: bounds.height)
        
        context?.drawLinearGradient(gradient, start: graphStartPoint, end: graphEndPoint, options: [])
        context?.restoreGState()
        
        //draw the line on top of the clipped gradient
        graphPath.lineWidth = 2.0
        graphPath.stroke()
        
        //Draw horizontal graph lines on the top of everything
        let linePath = UIBezierPath()
        
        /*
        //top line
        linePath.move(to: CGPoint(x: margin, y: topBorder))
        linePath.addLine(to: CGPoint(x: width - margin, y: topBorder))
        
        //center line
        linePath.move(to: CGPoint(x: margin, y: graphHeight/2 + topBorder))
        linePath.addLine(to: CGPoint(x: width - margin, y: graphHeight/2 + topBorder))
        
        //bottom line
        linePath.move(to: CGPoint(x: margin, y:height - bottomBorder))
        linePath.addLine(to: CGPoint(x:  width - margin, y: height - bottomBorder))
        
        
        let color = UIColor(white: 1.0, alpha: Constants.colorAlpha)
        color.setStroke()
        linePath.lineWidth = 1.0
        linePath.stroke()*/
        
    }

}
