//
//  SSTapDetectingImageView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit
public protocol SSTapDetectingImageViewDelegate: class {
	func imageView(_ imageView: UIImageView, singleTapDetected touch: UITouch)
	func imageView(_ imageView: UIImageView, doubleTapDetected touch: UITouch)
	func imageView(_ imageView: UIImageView, tripleTapDetected touch: UITouch)
}
public final class SSTapDetectingImageView: UIImageView {
    
	open weak var tapDelegate: SSTapDetectingImageViewDelegate!

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

	private func initialize() { isUserInteractionEnabled = true }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let tapCount = touch.tapCount
        switch tapCount {
        case 1: tapDelegate?.imageView(self, singleTapDetected: touch)
        case 2: tapDelegate?.imageView(self, doubleTapDetected: touch)
        case 3: tapDelegate?.imageView(self, tripleTapDetected: touch)
        default: break
        }
        next?.touchesEnded(touches, with: event)
    }
}
 
