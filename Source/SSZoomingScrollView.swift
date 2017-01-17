//
//  SSZoomingScrollView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit

open class SSZoomingScrollView: UIScrollView {

	open var photo: SSPhoto?
	open var captionView: SSCaptionView?
	open var photoImageView: SSTapDetectingImageView?
	open var tapView: SSTapDetectingView?

	fileprivate var progressView: ProgressView?
	fileprivate weak var photoBrowser: SSImageBrowser?

	convenience init(aPhotoBrowser: SSImageBrowser) {
		self.init(frame: CGRect.zero)
		photoBrowser = aPhotoBrowser
		// Tap view for background
		let _tapView = SSTapDetectingView(frame: self.bounds)
		_tapView.tapDelegate = self
		_tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		_tapView.backgroundColor = UIColor.clear
		addSubview(_tapView)
        tapView = _tapView

		// Image view
		let _photoImageView = SSTapDetectingImageView(frame: CGRect.zero)
		_photoImageView.tapDelegate = self
		_photoImageView.backgroundColor = UIColor.clear
		addSubview(_photoImageView)
        photoImageView = _photoImageView
        
		let screenBound = UIScreen.main.bounds
		var screenWidth = screenBound.size.width
		var screenHeight = screenBound.size.height
		let orientation = UIDevice.current.orientation
		if orientation == UIDeviceOrientation.landscapeLeft ||
		orientation == UIDeviceOrientation.landscapeRight {
			screenWidth = screenBound.size.height
			screenHeight = screenBound.size.width
		}

		// Progress view
		let color = aPhotoBrowser.progressTintColor != nil ? aPhotoBrowser.progressTintColor : UIColor(white: 1.0, alpha: 1)
		progressView = ProgressView(color: color!, frame: CGRect(x: (screenWidth - 35) / 2, y: (screenHeight - 35) / 2, width: 35.0, height: 35.0))
		progressView?.progress = 0
		progressView?.tag = 101
        if let v = progressView { addSubview(v) }

		// Setup
		backgroundColor = UIColor.clear
		delegate = self
		showsHorizontalScrollIndicator = false
		showsVerticalScrollIndicator = false
		decelerationRate = UIScrollViewDecelerationRateFast
		autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	open func prepareForReuse() {
		photo = nil
		captionView?.removeFromSuperview()
		captionView = nil
		tag = 0
	}

	open func setAPhoto(_ aPhoto: SSPhoto) {
		photoImageView?.image = nil // Release image
		if aPhoto != photo { photo = aPhoto }
		displayImage()
	}

	open func setProgress(_ progress: CGFloat, forPhoto aPhoto: SSPhoto!) {
        guard let progressView = progressView else { return }
		if let url = photo?.photoURL?.absoluteString {
			if aPhoto.photoURL?.absoluteString == url {
				if progressView.progress < progress {
					progressView.progress = progress
				}
			}
		} else if aPhoto.asset?.identifier == photo?.asset?.identifier {
			if progressView.progress < progress {
				progressView.progress = progress
			}
		}

	}

	open func displayImage() {
		if let p = photo {
			// Reset
			self.maximumZoomScale = 1
			self.minimumZoomScale = 1
			self.zoomScale = 1

			self.contentSize = CGSize(width: 0, height: 0)

			// Get image from browser as it handles ordering of fetching
			if let img = photoBrowser?.imageForPhoto(p) {
				// Hide ProgressView
				// progressView.alpha = 0.0f
				progressView?.removeFromSuperview()

				// Set image
				photoImageView?.image = img
				photoImageView?.isHidden = false

				// Setup photo frame
				var photoImageViewFrame = CGRect.zero
				photoImageViewFrame.origin = CGPoint.zero
				photoImageViewFrame.size = img.size

				photoImageView?.frame = photoImageViewFrame
				self.contentSize = photoImageViewFrame.size

				// Set zoom to minimum zoom
				setMaxMinZoomScalesForCurrentBounds()
			} else {
				// Hide image view
				photoImageView?.isHidden = true

				progressView?.alpha = 1.0
			}

			self.setNeedsLayout()
		}
	}

	open func displayImageFailure() {
		progressView?.removeFromSuperview()
	}

	open func setMaxMinZoomScalesForCurrentBounds() {
		// Reset
		self.maximumZoomScale = 1
		self.minimumZoomScale = 1
		self.zoomScale = 1

		// fail
		if photoImageView?.image == nil {
			return
		}

		// Sizes
		let boundsSize = bounds.size
		let imageSize = photoImageView?.frame.size ?? .zero

		// Calculate Min
		let xScale = boundsSize.width / imageSize.width // the scale needed to perfectly fit the image width-wise
		let yScale = boundsSize.height / imageSize.height // the scale needed to perfectly fit the image height-wise
		let minScale = min(xScale, yScale) // use minimum of these to allow the image to become fully visible

		// If image is smaller than the screen then ensure we show it at
		// min scale of 1
		if xScale > 1 && yScale > 1 {
			// minScale = 1.0
		}

		// Calculate Max
		var maxScale: CGFloat = 4.0 // Allow double scale
		// on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
		// maximum zoom scale to 0.5.

		maxScale = maxScale / UIScreen.main.scale

		if (maxScale < minScale) {
			maxScale = minScale * 2
		}

		// Set
		self.maximumZoomScale = maxScale
		self.minimumZoomScale = minScale
		self.zoomScale = minScale

		// Reset position
		photoImageView?.frame = CGRect(x: 0, y: 0, width: photoImageView?.frame.size.width ?? 0, height: photoImageView?.frame.size.height ?? 0)
		self.setNeedsLayout()
	}

	open override func layoutSubviews() {
		// Update tap view frame
		tapView?.frame = bounds

		// Super
		super.layoutSubviews()

		// Center the image as it becomes smaller than the size of the screen
		let boundsSize = self.bounds.size
		var frameToCenter = photoImageView?.frame ?? .zero

		// Horizontally
		if frameToCenter.size.width < boundsSize.width {
			frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
		} else {
			frameToCenter.origin.x = 0
		}

		// Vertically
		if frameToCenter.size.height < boundsSize.height {
			frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
		} else {
			frameToCenter.origin.y = 0
		}

		// Center
		if photoImageView?.frame.equalTo(frameToCenter) == false {
			photoImageView?.frame = frameToCenter
		}
	}

}
// MARK: - UIScrollViewDelegate
extension SSZoomingScrollView: UIScrollViewDelegate {

	public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return photoImageView
	}

	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		photoBrowser?.cancelControlHiding()
	}

	public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
		photoBrowser?.cancelControlHiding()
	}

	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		photoBrowser?.hideControlsAfterDelay()
	}

	public func scrollViewDidZoom(_ scrollView: UIScrollView) {
		setNeedsLayout()
		layoutIfNeeded()
	}
}

extension SSZoomingScrollView: SSTapDetectingViewDelegate, SSTapDetectingImageViewDelegate {

	fileprivate func handleSingleTap(_ touchPoint: CGPoint) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { () -> Void in
			self.photoBrowser?.toggleControls()
		}
	}

	fileprivate func handleDoubleTap(_ touchPoint: CGPoint) {

		// Cancel any single tap handling
        if let p = photoBrowser { NSObject.cancelPreviousPerformRequests(withTarget: p) }
		// Zoom
		if zoomScale == maximumZoomScale {
			setZoomScale(minimumZoomScale, animated: true)
		} else {
			zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
		}
		// Delay controls
		photoBrowser?.hideControlsAfterDelay()
	}

	public func imageView(_ imageView: UIImageView, singleTapDetected touch: UITouch) {
		handleSingleTap(touch.location(in: imageView))
	}

	public func imageView(_ imageView: UIImageView, doubleTapDetected touch: UITouch) {
		handleDoubleTap(touch.location(in: imageView))
	}

	public func imageView(_ imageView: UIImageView, tripleTapDetected touch: UITouch) {

	}

	public func view(_ view: UIView, singleTapDetected touch: UITouch) {
		handleSingleTap(touch.location(in: view))
	}
	public func view(_ view: UIView, doubleTapDetected touch: UITouch) {
		handleDoubleTap(touch.location(in: view))
	}
	public func view(_ view: UIView, tripleTapDetected touch: UITouch) {

	}

}

private class ProgressView: UIView {

	var progress: CGFloat = 0 {
		didSet {
			var p = progress
			if p > 1 { p = 1 }
			if p < 0 { p = 0 }
			progressLayer.strokeEnd = p
		}
	}
	fileprivate let progressLayer = CAShapeLayer()

	convenience init(color: UIColor, frame: CGRect) {
		self.init(frame: frame)
		createProgressLayer(color)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		createProgressLayer()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	fileprivate func createProgressLayer(_ color: UIColor = UIColor.white) {
		let startAngle = CGFloat(M_PI_2)
		let endAngle = CGFloat(M_PI * 2 + M_PI_2)
		let centerPoint = CGPoint(x: frame.width / 2, y: frame.height / 2)

		let gradientMaskLayer = gradientMask(color)
		progressLayer.path = UIBezierPath(arcCenter: centerPoint, radius: frame.width / 2 - 30.0, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
		progressLayer.backgroundColor = UIColor.clear.cgColor
		progressLayer.fillColor = nil
		progressLayer.strokeColor = UIColor.black.cgColor
		progressLayer.lineWidth = 4.0
		progressLayer.strokeStart = 0.0
		progressLayer.strokeEnd = 0.0

		gradientMaskLayer.mask = progressLayer
		layer.addSublayer(gradientMaskLayer)
	}

	fileprivate func gradientMask(_ color: UIColor) -> CAGradientLayer {
		let gradientLayer = CAGradientLayer()
		gradientLayer.frame = bounds
		gradientLayer.locations = [0.0, 1.0]
		let colorTop: AnyObject = color.cgColor
		let colorBottom: AnyObject = color.cgColor
		let arrayOfColors: [AnyObject] = [colorTop, colorBottom]
		gradientLayer.colors = arrayOfColors

		return gradientLayer
	}

	func hideProgressView() {
		progressLayer.opacity = 0
		progressLayer.strokeEnd = 0.0
	}

}
