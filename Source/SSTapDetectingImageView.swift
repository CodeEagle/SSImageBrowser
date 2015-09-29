//
//  SSTapDetectingImageView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit
public protocol SSTapDetectingImageViewDelegate: class {
    func imageView(imageView: UIImageView, singleTapDetected touch: UITouch)
    func imageView(imageView: UIImageView, doubleTapDetected touch: UITouch)
    func imageView(imageView: UIImageView, tripleTapDetected touch: UITouch)
}
public class SSTapDetectingImageView: UIImageView {
    public var tapDelegate: SSTapDetectingImageViewDelegate!
    
    
    override init(image: UIImage!) {
        super.init(image: image)
        initialize()
    }
    
    override init(image: UIImage!, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.userInteractionEnabled = true
    }
    
}
extension SSTapDetectingImageView {
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let tapCount = touch.tapCount
        switch tapCount {
        case 1:
            tapDelegate?.imageView(self, singleTapDetected: touch)
            break
        case 2:
            tapDelegate?.imageView(self, doubleTapDetected: touch)
            break
        case 3:
            tapDelegate?.imageView(self, tripleTapDetected: touch)
            break
        default:
            break
        }
        self.nextResponder()?.touchesEnded(touches, withEvent: event)

    }
}
