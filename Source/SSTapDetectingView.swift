//
//  SSTapDetectingView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit

public protocol SSTapDetectingViewDelegate: class {
    func view(view: UIView, singleTapDetected touch: UITouch)
    func view(view: UIView, doubleTapDetected touch: UITouch)
    func view(view: UIView, tripleTapDetected touch: UITouch)
}
public class SSTapDetectingView: UIImageView {
    public var tapDelegate: SSTapDetectingViewDelegate!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.userInteractionEnabled = true
    }
    
}
extension SSTapDetectingView {
    
    public override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let tapCount = touch.tapCount
        switch tapCount {
        case 1:
            tapDelegate?.view(self, singleTapDetected: touch)
            break
        case 2:
            tapDelegate?.view(self, doubleTapDetected: touch)
            break
        case 3:
            tapDelegate?.view(self, tripleTapDetected: touch)
            break
        default:
            break
        }
        self.nextResponder()?.touchesEnded(touches, withEvent: event)
    }
}