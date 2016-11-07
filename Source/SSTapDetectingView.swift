//
//  SSTapDetectingView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit

public protocol SSTapDetectingViewDelegate: class {
	func view(_ view: UIView, singleTapDetected touch: UITouch)
	func view(_ view: UIView, doubleTapDetected touch: UITouch)
	func view(_ view: UIView, tripleTapDetected touch: UITouch)
}
open class SSTapDetectingView: UIImageView {
	open weak var tapDelegate: SSTapDetectingViewDelegate!

	override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}

	func initialize() {
		self.isUserInteractionEnabled = true
	}
}
extension SSTapDetectingView {

	open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {
			return
		}

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
		self.next?.touchesEnded(touches, with: event)
	}
}
