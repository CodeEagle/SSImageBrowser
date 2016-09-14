//
//  SSZoomingScrollView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit

public class SSZoomingScrollView: UIScrollView {

	public var photo: SSPhoto!
	public var captionView: SSCaptionView!
	public var photoImageView: SSTapDetectingImageView!
	public var tapView: SSTapDetectingView!

	private var progressView: ProgressView!
	private weak var photoBrowser: SSImageBrowser!

	convenience init(aPhotoBrowser: SSImageBrowser) {
		self.init(frame: CGRectZero)
		photoBrowser = aPhotoBrowser
		// Tap view for background
		tapView = SSTapDetectingView(frame: self.bounds)
		tapView.tapDelegate = self
		tapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		tapView.backgroundColor = UIColor.clearColor()
		addSubview(tapView)

		// Image view
		photoImageView = SSTapDetectingImageView(frame: CGRectZero)
		photoImageView.tapDelegate = self
		photoImageView.backgroundColor = UIColor.clearColor()
		addSubview(photoImageView)
		let screenBound = UIScreen.mainScreen().bounds
		var screenWidth = screenBound.size.width
		var screenHeight = screenBound.size.height
		let orientation = UIDevice.currentDevice().orientation
		if orientation == UIDeviceOrientation.LandscapeLeft ||
		orientation == UIDeviceOrientation.LandscapeRight {
			screenWidth = screenBound.size.height
			screenHeight = screenBound.size.width
		}

		// Progress view
		let color = aPhotoBrowser.progressTintColor != nil ? photoBrowser.progressTintColor : UIColor(white: 1.0, alpha: 1)
		progressView = ProgressView(color: color, frame: CGRectMake((screenWidth - 35) / 2, (screenHeight - 35) / 2, 35.0, 35.0))
		progressView.progress = 0
		progressView.tag = 101
		addSubview(progressView)
		// Setup
		backgroundColor = UIColor.clearColor()
		delegate = self
		showsHorizontalScrollIndicator = false
		showsVerticalScrollIndicator = false
		decelerationRate = UIScrollViewDecelerationRateFast
		autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	public func prepareForReuse() {
		photo = nil
		captionView?.removeFromSuperview()
		captionView = nil
		self.tag = 0
	}

	public func setAPhoto(aPhoto: SSPhoto) {
		photoImageView.image = nil // Release image
		if aPhoto != photo {
			photo = aPhoto
		}
		displayImage()
	}

	public func setProgress(progress: CGFloat, forPhoto aPhoto: SSPhoto?) {
        guard let targetPhoto = aPhoto else { return }
		if let url = photo?.photoURL?.absoluteString {
			if targetPhoto.photoURL.absoluteString == url {
				if progressView.progress < progress {
					progressView.progress = progress
				}
			}
		} else if targetPhoto.asset.identifier == photo?.asset?.identifier {
			if progressView.progress < progress {
				progressView.progress = progress
			}
		}

	}

	public func displayImage() {
		if let p = photo {
			// Reset
			self.maximumZoomScale = 1
			self.minimumZoomScale = 1
			self.zoomScale = 1

			self.contentSize = CGSizeMake(0, 0)

			// Get image from browser as it handles ordering of fetching
			if let img = photoBrowser.imageForPhoto(p) {
				// Hide ProgressView
				// progressView.alpha = 0.0f
				progressView.removeFromSuperview()

				// Set image
				photoImageView.image = img
				photoImageView.hidden = false

				// Setup photo frame
				var photoImageViewFrame = CGRectZero
				photoImageViewFrame.origin = CGPointZero
				photoImageViewFrame.size = img.size

				photoImageView.frame = photoImageViewFrame
				self.contentSize = photoImageViewFrame.size

				// Set zoom to minimum zoom
				setMaxMinZoomScalesForCurrentBounds()
			} else {
				// Hide image view
				photoImageView.hidden = true

				progressView.alpha = 1.0
			}

			self.setNeedsLayout()
		}
	}

	public func displayImageFailure() {
		progressView.removeFromSuperview()
	}

	public func setMaxMinZoomScalesForCurrentBounds() {
		// Reset
		self.maximumZoomScale = 1
		self.minimumZoomScale = 1
		self.zoomScale = 1

		// fail
		if photoImageView.image == nil {
			return
		}

		// Sizes
		let boundsSize = self.bounds.size
		let imageSize = photoImageView.frame.size

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

		maxScale = maxScale / UIScreen.mainScreen().scale

		if (maxScale < minScale) {
			maxScale = minScale * 2
		}

		// Set
		self.maximumZoomScale = maxScale
		self.minimumZoomScale = minScale
		self.zoomScale = minScale

		// Reset position
		photoImageView.frame = CGRectMake(0, 0, photoImageView.frame.size.width, photoImageView.frame.size.height)
		self.setNeedsLayout()
	}

	public override func layoutSubviews() {
		// Update tap view frame
		tapView.frame = self.bounds

		// Super
		super.layoutSubviews()

		// Center the image as it becomes smaller than the size of the screen
		let boundsSize = self.bounds.size
		var frameToCenter = photoImageView.frame

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
		if !CGRectEqualToRect(photoImageView.frame, frameToCenter) {
			photoImageView.frame = frameToCenter
		}
	}

}
// MARK: - UIScrollViewDelegate
extension SSZoomingScrollView: UIScrollViewDelegate {

	public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		return photoImageView
	}

	public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		photoBrowser.cancelControlHiding()
	}

	public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
		photoBrowser.cancelControlHiding()
	}

	public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		photoBrowser.hideControlsAfterDelay()
	}

	public func scrollViewDidZoom(scrollView: UIScrollView) {
		setNeedsLayout()
		layoutIfNeeded()
	}
}

extension SSZoomingScrollView: SSTapDetectingViewDelegate, SSTapDetectingImageViewDelegate {

	private func handleSingleTap(touchPoint: CGPoint) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
			self.photoBrowser.toggleControls()
		}
	}

	private func handleDoubleTap(touchPoint: CGPoint) {

		// Cancel any single tap handling
		NSObject.cancelPreviousPerformRequestsWithTarget(photoBrowser)

		// Zoom
		if self.zoomScale == self.maximumZoomScale {
			self.setZoomScale(self.minimumZoomScale, animated: true)

		} else {
			self.zoomToRect(CGRectMake(touchPoint.x, touchPoint.y, 1, 1), animated: true)

		}

		// Delay controls
		photoBrowser.hideControlsAfterDelay()
	}

	public func imageView(imageView: UIImageView, singleTapDetected touch: UITouch) {
		handleSingleTap(touch.locationInView(imageView))
	}

	public func imageView(imageView: UIImageView, doubleTapDetected touch: UITouch) {
		handleDoubleTap(touch.locationInView(imageView))
	}

	public func imageView(imageView: UIImageView, tripleTapDetected touch: UITouch) {

	}

	public func view(view: UIView, singleTapDetected touch: UITouch) {
		handleSingleTap(touch.locationInView(view))
	}
	public func view(view: UIView, doubleTapDetected touch: UITouch) {
		handleDoubleTap(touch.locationInView(view))
	}
	public func view(view: UIView, tripleTapDetected touch: UITouch) {

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
	private let progressLayer = CAShapeLayer()

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

	private func createProgressLayer(color: UIColor = UIColor.whiteColor()) {
		let startAngle = CGFloat(M_PI_2)
		let endAngle = CGFloat(M_PI * 2 + M_PI_2)
		let centerPoint = CGPointMake(CGRectGetWidth(frame) / 2, CGRectGetHeight(frame) / 2)

		let gradientMaskLayer = gradientMask(color)
		progressLayer.path = UIBezierPath(arcCenter: centerPoint, radius: CGRectGetWidth(frame) / 2 - 30.0, startAngle: startAngle, endAngle: endAngle, clockwise: true).CGPath
		progressLayer.backgroundColor = UIColor.clearColor().CGColor
		progressLayer.fillColor = nil
		progressLayer.strokeColor = UIColor.blackColor().CGColor
		progressLayer.lineWidth = 4.0
		progressLayer.strokeStart = 0.0
		progressLayer.strokeEnd = 0.0

		gradientMaskLayer.mask = progressLayer
		layer.addSublayer(gradientMaskLayer)
	}

	private func gradientMask(color: UIColor) -> CAGradientLayer {
		let gradientLayer = CAGradientLayer()
		gradientLayer.frame = bounds
		gradientLayer.locations = [0.0, 1.0]
		let colorTop: AnyObject = color.CGColor
		let colorBottom: AnyObject = color.CGColor
		let arrayOfColors: [AnyObject] = [colorTop, colorBottom]
		gradientLayer.colors = arrayOfColors

		return gradientLayer
	}

	func hideProgressView() {
		progressLayer.opacity = 0
		progressLayer.strokeEnd = 0.0
	}

}