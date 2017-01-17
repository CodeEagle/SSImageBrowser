//
//  SSImageBrowser.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit
// MARK: - SSImageBrowserDelegate
@objc public protocol SSImageBrowserDelegate: class {
	@objc optional func photoBrowser(_ photoBrowser: SSImageBrowser, didShowPhotoAtIndex index: Int)
	@objc optional func photoBrowser(_ photoBrowser: SSImageBrowser, didDismissAtPageIndex index: Int)
	@objc optional func photoBrowser(_ photoBrowser: SSImageBrowser, willDismissAtPageIndex index: Int)
	@objc optional func photoBrowser(_ photoBrowser: SSImageBrowser, captionViewForPhotoAtIndex index: Int) -> SSCaptionView!
	@objc optional func photoBrowser(_ photoBrowser: SSImageBrowser, didDismissActionSheetWithButtonIndex index: Int, photoIndex: Int)
}
public let UIApplicationSaveImageToCameraRoll = "UIApplicationSaveImageToCameraRoll"
// MARK: - SSImageBrowser
open class SSImageBrowser: UIViewController {

	// MARK: - public
	open weak var delegate: SSImageBrowserDelegate?
	open lazy var displayToolbar = true
	open lazy var displayCounterLabel = true
	open lazy var displayArrowButton = true
	open lazy var displayActionButton = true
	open lazy var displayDoneButton = true
	open lazy var useWhiteBackgroundColor = false
	open lazy var arrowButtonsChangePhotosAnimated = true
	open lazy var forceHideStatusBar = false
	open lazy var usePopAnimation = true
	open lazy var disableVerticalSwipe = false

	open lazy var actionButtonTitles = [String]()
	open lazy var backgroundScaleFactor: CGFloat = 1
	open lazy var animationDuration: CGFloat = 0.28

	open weak var leftArrowImage: UIImage!
	open weak var leftArrowSelectedImage: UIImage!
	open weak var rightArrowImage: UIImage!
	open weak var rightArrowSelectedImage: UIImage!
    open var doneButtonFrame: CGRect?
	open var doneButtonImage: UIImage!
	open var doneButtonImageForeground: UIImage!
	open weak var scaleImage: UIImage!

	open weak var trackTintColor: UIColor!
	open weak var progressTintColor: UIColor!

	// MARK: - Private
	fileprivate lazy var photos: [SSPhoto]! = [SSPhoto]()
	fileprivate lazy var pagingScrollView = UIScrollView()
	fileprivate lazy var pageIndexBeforeRotation: UInt = 0
	fileprivate lazy var currentPageIndex = 0
	fileprivate lazy var initalPageIndex = 0
	fileprivate var statusBarOriginallyHidden = false
	fileprivate var performingLayout = false
	fileprivate var rotating = false
	fileprivate var viewIsActive = false
	fileprivate var autoHide = true
	fileprivate var isdraggingPhoto = false
	fileprivate lazy var visiblePages: Set<SSZoomingScrollView>! = Set<SSZoomingScrollView>()
	fileprivate lazy var recycledPages: Set<SSZoomingScrollView>! = Set<SSZoomingScrollView>()

	fileprivate var panGesture: UIPanGestureRecognizer!
	fileprivate var doneButton: UIButton!
	fileprivate var toolbar: UIToolbar!
	fileprivate var previousButton: UIBarButtonItem!
	fileprivate var nextButton: UIBarButtonItem!
	fileprivate var actionButton: UIBarButtonItem!
	fileprivate var counterButton: UIBarButtonItem!
	fileprivate var counterLabel: UILabel!
	fileprivate var actionsSheet: UIAlertController!
	fileprivate var activityViewController: UIActivityViewController!
	fileprivate weak var senderViewForAnimation: UIView!
	fileprivate var senderViewOriginalFrame: CGRect!
	fileprivate var applicationWindow: UIWindow!
	fileprivate var applicationTopViewController: UIViewController!

	fileprivate var firstX: CGFloat = 0
	fileprivate var firstY: CGFloat = 0

	fileprivate var hideTask: CancelableTask!
	fileprivate var _completion: (() -> ())?

	fileprivate func areControlsHidden() -> Bool {
		if let t = toolbar {
			return t.alpha == 0
		}
		return true
	}

	deinit {
		pagingScrollView.delegate = nil
		NotificationCenter.default.removeObserver(self)
		releaseAllUnderlyingPhotos()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	init() {
		super.init(nibName: nil, bundle: nil)
		// Defaults
		initialize()
	}

	fileprivate func initialize() {
		view.tintColor = UIColor.white
		hidesBottomBarWhenPushed = true
		automaticallyAdjustsScrollViewInsets = false
		modalPresentationStyle = UIModalPresentationStyle.custom
		modalTransitionStyle = UIModalTransitionStyle.crossDissolve
		modalPresentationCapturesStatusBarAppearance = true
		applicationWindow = UIApplication.shared.delegate?.window!
		// Listen for IDMPhoto notifications
		NotificationCenter.default.addObserver(self, selector: #selector(handleSSPhotoLoadingDidEndNotification(_:)), name: NSNotification.Name.SSPhotoLoadingDidEnd, object: nil)
	}

	// MARK: - SSPhoto Loading Notification
	func handleSSPhotoLoadingDidEndNotification(_ notification: Notification) {
		DispatchQueue.main.async(execute: { () -> Void in
			if let photo = notification.object as? SSPhoto {
				if let page = self.pageDisplayingPhoto(photo) {
					if photo.underlyingImage() != nil {
						page.displayImage()
						self.loadAdjacentPhotosIfNecessary(photo)
					} else {
						page.displayImageFailure()
					}
				}
			}
		})
	}
}
// MARK: - Init
extension SSImageBrowser {

	public convenience init(aPhotos: [SSPhoto], animatedFromView view: UIView! = nil) {
		self.init()
		photos = aPhotos
		senderViewForAnimation = view
		performPresentAnimation()
	}

	public convenience init(aURLs: [URL], animatedFromView view: UIView! = nil) {
		self.init()
		let aPhotos = SSPhoto.photosWithURLs(aURLs)
		photos = aPhotos
		senderViewForAnimation = view
		performPresentAnimation()
	}
}
// MARK: - Life Cycle
extension SSImageBrowser {
	override open func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha: 1)
		view.clipsToBounds = true

		// Setup paging scrolling view
		let pagingScrollViewFrame = frameForPagingScrollView()
		pagingScrollView = UIScrollView(frame: pagingScrollViewFrame)
		pagingScrollView.isPagingEnabled = true
		pagingScrollView.delegate = self
		pagingScrollView.showsHorizontalScrollIndicator = false
		pagingScrollView.showsVerticalScrollIndicator = false
		pagingScrollView.backgroundColor = UIColor.clear
		pagingScrollView.contentSize = contentSizeForPagingScrollView()
		view.addSubview(pagingScrollView)

//        // Transition animation
//        performPresentAnimation()

		let currentOrientation = UIApplication.shared.statusBarOrientation

		// Toolbar
		toolbar = UIToolbar(frame: frameForToolbarAtOrientation(currentOrientation))
		toolbar.backgroundColor = UIColor.clear
		toolbar.clipsToBounds = true
		toolbar.isTranslucent = true
		toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: UIBarMetrics.default)

		// Close Button
		doneButton = UIButton(type: .custom)
		doneButton.frame = frameForDoneButtonAtOrientation(currentOrientation)
		doneButton.alpha = 1.0
		doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)

		let bundle = Bundle(for: SSImageBrowser.self)
		var imageBundle: Bundle?
		if let path = bundle.path(forResource: "IDMPhotoBrowser", ofType: "bundle") {
			imageBundle = Bundle(path: path)
		}
		let scale = Int(UIScreen.main.scale)
		var leftOff = leftArrowImage
		if let path = imageBundle?.path(forResource: "images/left\(scale)x", ofType: "png") , leftArrowImage == nil {
			leftOff = UIImage(contentsOfFile: path)?.withRenderingMode(.alwaysTemplate)
		}
		var rightOff = rightArrowImage
		if let path = imageBundle?.path(forResource: "images/right\(scale)x", ofType: "png") , rightArrowImage == nil {
			rightOff = UIImage(contentsOfFile: path)?.withRenderingMode(.alwaysTemplate)
		}
		let leftOn = leftArrowSelectedImage ?? leftOff

		let rightOn = rightArrowSelectedImage ?? rightOff

		// Arrows
		previousButton = UIBarButtonItem(customView: customToolbarButtonImage(leftOff!, imageSelected: leftOn!, action: #selector(gotoPreviousPage)))

		nextButton = UIBarButtonItem(customView: customToolbarButtonImage(rightOff!, imageSelected: rightOn!, action: #selector(gotoNextPage)))

		// Counter Label
		counterLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 95, height: 40))
		counterLabel.textAlignment = .center
		counterLabel.backgroundColor = UIColor.clear
		counterLabel.font = UIFont(name: "Helvetica", size: 17)

		if !useWhiteBackgroundColor {
			counterLabel.textColor = UIColor.white
			counterLabel.shadowColor = UIColor.darkText
			counterLabel.shadowOffset = CGSize(width: 0, height: 1)
		}
		else {
			counterLabel.textColor = UIColor.black
		}

		// Counter Button
		counterButton = UIBarButtonItem(customView: counterLabel)

		// Action Button
		actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionButtonPressed(_:)))

		// Gesture
		panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
	}
	open override func viewWillAppear(_ animated: Bool) {
		reloadData()
		super.viewWillAppear(animated)

		// Status Bar
		statusBarOriginallyHidden = UIApplication.shared.isStatusBarHidden

		// Update UI
		hideControlsAfterDelay()

		if doneButtonImage == nil && doneButtonImageForeground == nil {
			doneButton.setTitleColor(UIColor(white: 0.9, alpha: 0.9), for: .highlighted)
			doneButton.setTitle(SSPhotoBrowserLocalizedStrings("X"), for: .normal)
			doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
			doneButton.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
			doneButton.sizeToFit()
			doneButton.layer.cornerRadius = doneButton.bounds.size.width / 2
		} else if doneButtonImageForeground != nil {
			doneButton.setImage(doneButtonImageForeground, for: .normal)
			doneButton.contentMode = .center
		} else if doneButtonImage != nil {
			doneButton.setBackgroundImage(doneButtonImage, for: .normal)
			doneButton.contentMode = .scaleAspectFit
		}
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		viewIsActive = true
	}

	open override func viewWillLayoutSubviews() {
		// Flag
		performingLayout = true

		let currentOrientation = UIApplication.shared.statusBarOrientation

		// Toolbar
		toolbar.frame = frameForToolbarAtOrientation(currentOrientation)

		// Done button
		doneButton.frame = frameForDoneButtonAtOrientation(currentOrientation)

		// Remember index
		let indexPriorToLayout = currentPageIndex

		// Get paging scroll view frame to determine if anything needs changing
		let pagingScrollViewFrame = frameForPagingScrollView()

		// Frame needs changing
		pagingScrollView.frame = pagingScrollViewFrame

		// Recalculate contentSize based on current orientation
		pagingScrollView.contentSize = contentSizeForPagingScrollView()

		// Adjust frames and configuration of each visible page
		for page in visiblePages {

			let index = PAGE_INDEX(page)
			page.frame = frameForPageAtIndex(index)

			if let captionView = page.captionView {
				captionView.frame = frameForCaptionView(captionView, atIndex: index)
			}
			page.setMaxMinZoomScalesForCurrentBounds()
		}

		// Adjust contentOffset to preserve page location based on values collected prior to location
		pagingScrollView.contentOffset = contentOffsetForPageAtIndex(indexPriorToLayout)
		didStartViewingPageAtIndex(currentPageIndex) // initial

		// Reset
		currentPageIndex = indexPriorToLayout
		performingLayout = false

		// Super
		super.viewWillLayoutSubviews()
	}

	override open func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		releaseAllUnderlyingPhotos()
		recycledPages.removeAll(keepingCapacity: false)
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.post(name: Notification.Name(rawValue: "stopAllRequest"), object: nil)
	}
}
// MARK: - Public Func
extension SSImageBrowser {
	public func reloadData() {
		releaseAllUnderlyingPhotos()
		performLayout()
		view.setNeedsLayout()
	}

	public func setInitialPageIndex(_ index: Int) {
		let count = numberOfPhotos()
		var i = index
		if index >= count { i = count - 1 }
		initalPageIndex = i
		currentPageIndex = i
		if isViewLoaded {
			jumpToPageAtIndex(i)
			if !viewIsActive {
				tilePages()
			}
		}
	}

	public func photoAtIndex(_ index: Int) -> SSPhoto {
		return photos[index]
	}

	// MARK: - Status Bar

	open override var preferredStatusBarStyle : UIStatusBarStyle {
		return useWhiteBackgroundColor ? .default : .lightContent
	}

	open override var prefersStatusBarHidden : Bool {
		if forceHideStatusBar {
			return true
		}
		if isdraggingPhoto {
			if statusBarOriginallyHidden {
				return true
			} else {
				return false
			}
		} else {
			return areControlsHidden()
		}
	}

	open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
		return .fade
	}
}
// MARK: - UIScrollViewDelegate
extension SSImageBrowser: UIScrollViewDelegate {

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if !viewIsActive || performingLayout || rotating {
			return
		}
		setControlsHidden(true, animated: false, permanent: false)
		tilePages()
		let visibleBounds = pagingScrollView.bounds
		let x = visibleBounds.midX
		let width = visibleBounds.width
		let f = x / width
		var index = Int(floor(f))
		if index < 0 {
			index = 0
		}
		let count = numberOfPhotos() - 1
		if index > count {
			index = count
		}
		let previousCurrentPage = currentPageIndex
		currentPageIndex = index
		if currentPageIndex != previousCurrentPage {
			didStartViewingPageAtIndex(index)
			if arrowButtonsChangePhotosAnimated {
				updateToolbar()
			}
		}
	}

	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		// Hide controls when dragging begins
		setControlsHidden(true, animated: true, permanent: false)
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		// Update toolbar when page changes
		if !arrowButtonsChangePhotosAnimated {
			updateToolbar()
		}
	}
}
// MARK: - Private Func
extension SSImageBrowser {

	// MARK: - Pan Gesture
	func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
		// Initial Setup
		let scrollView = pageDisplayedAtIndex(currentPageIndex)
		if scrollView == nil {
			return
		}

		let viewHeight = scrollView?.frame.size.height
		let viewHalfHeight = viewHeight! / 2

		var translatedPoint = sender.translation(in: view)

		// Gesture Began
		if sender.state == .began {
			setControlsHidden(true, animated: true, permanent: true)
			firstX = (scrollView?.center.x)!
			firstY = (scrollView?.center.y)!
			senderViewForAnimation?.isHidden = currentPageIndex == initalPageIndex
			isdraggingPhoto = true
			setNeedsStatusBarAppearanceUpdate()
		}

		translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
		scrollView?.center = translatedPoint

		let newY = (scrollView?.center.y)! - viewHalfHeight
		let newAlpha = 1 - fabs(newY) / viewHeight! // abs(newY)/viewHeight * 1.8
		view.isOpaque = true
		view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha: newAlpha)

		// Gesture Ended
		if sender.state == .ended {

			if (scrollView?.center.y)! > viewHalfHeight + 40 || (scrollView?.center.y)! < viewHalfHeight - 40 {
				if senderViewForAnimation != nil && currentPageIndex == initalPageIndex {
					performCloseAnimationWithScrollView(scrollView!)
					return
				}
				let finalX = firstX
				var finalY: CGFloat = 0
				let windowsHeigt = applicationWindow.frame.size.height

				if (scrollView?.center.y)! > viewHalfHeight + 30 {
					finalY = windowsHeigt * 2
				} else {
					finalY = -viewHalfHeight
				}

				UIView.animate(withDuration: TimeInterval(animationDuration), animations: {
					scrollView?.center = CGPoint(x: finalX, y: finalY)
					self.view.backgroundColor = UIColor.clear
				})

				UIView.animate(withDuration: TimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
					scrollView?.center = CGPoint(x: finalX, y: finalY)
					}, completion: { (b) -> Void in
				})
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.35 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self] in
					guard let sself = self else { return }
					sself.doneButtonPressed()
				}
			} else {
				isdraggingPhoto = false
				setNeedsStatusBarAppearanceUpdate()
				view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha: 1)

				let velocityY = sender.velocity(in: view).y * 0.35

				let finalX = firstX
				let finalY = viewHalfHeight
				let animationDuration = abs(velocityY) * 0.0002 + 0.2
				UIView.animate(
					withDuration: TimeInterval(animationDuration),
					delay: 0,
					options: .curveEaseOut,
					animations: { scrollView?.center = CGPoint(x: finalX, y: finalY) },
					completion: nil)
			}
		}
	}
	// MARK: - Control Hiding / Showing

	func cancelControlHiding() {
		// If a timer exists then cancel and release
		cancel(hideTask)
	}

	func hideControlsAfterDelay() {
		if !areControlsHidden() {
			cancelControlHiding()
			hideTask = delay(5, work: { [weak self] in
				guard let sself = self else { return }
				sself.hideControls()
			})
		}
	}

	fileprivate func setControlsHidden(_ hidden: Bool, animated: Bool, permanent: Bool) {
		// Cancel any timers
		cancelControlHiding()

		// Captions
		var captionViews = Set<SSCaptionView>()
		for page in visiblePages {
			if let cap = page.captionView {
				captionViews.insert(cap)
			}
		}

		// Hide/show bars
		UIView.animate(withDuration: animated ? 0.1 : 0, animations: {
			let alpha: CGFloat = hidden ? 0 : 1
			self.navigationController?.navigationBar.alpha = alpha
			self.toolbar.alpha = alpha
			self.doneButton.alpha = alpha
			for v in captionViews {
				v.alpha = alpha
			}
		})

		// Control hiding timer
		// Will cancel existing timer but only begin hiding if they are visible
		if !permanent {
			hideControlsAfterDelay()
		}
		setNeedsStatusBarAppearanceUpdate()
	}

	fileprivate func hideControls() {
		if autoHide {
			setControlsHidden(true, animated: true, permanent: false)
		}
	}
	func toggleControls() {
		setControlsHidden(!areControlsHidden(), animated: true, permanent: false)
	}

	// MARK: - NSObject
	fileprivate func releaseAllUnderlyingPhotos() {
		for obj in photos {
			obj.unloadUnderlyingImage()
		}
	}

	// MARK: - Data
	fileprivate func numberOfPhotos() -> Int {
		return photos.count
	}

	fileprivate func captionViewForPhotoAtIndex(_ index: Int) -> SSCaptionView! {
		var captionView: SSCaptionView! = delegate?.photoBrowser?(self, captionViewForPhotoAtIndex: index)
		if captionView == nil {
			let photo = photoAtIndex(index)
			if let _ = photo.caption() {
				captionView = SSCaptionView(aPhoto: photo)
				captionView.alpha = areControlsHidden() ? 0 : 1
			}
		} else {
			captionView.alpha = areControlsHidden() ? 0 : 1
		}
		return captionView
	}

	func imageForPhoto(_ photo: SSPhoto!) -> UIImage! {
		if photo != nil {
			// Get image or obtain in background
			if photo.underlyingImage() != nil {
				return photo.underlyingImage()
			} else {
				photo.loadUnderlyingImageAndNotify()
				if let img = photo.placeholderImage() {
					return img
				}
			}
		}
		return nil
	}

	fileprivate func loadAdjacentPhotosIfNecessary(_ photo: SSPhoto) {
		if let page = pageDisplayingPhoto(photo) {
			let pageIndex = PAGE_INDEX(page)
			if currentPageIndex == pageIndex {
				if pageIndex > 0 {
					let photo = photoAtIndex(pageIndex - 1)
					if photo.underlyingImage() == nil {
						photo.loadUnderlyingImageAndNotify()
					}
				}
				let count = numberOfPhotos()
				if pageIndex < count - 1 {
					let photo = photoAtIndex(pageIndex + 1)
					if photo.underlyingImage() == nil {
						photo.loadUnderlyingImageAndNotify()
					}
				}
			}
		}
	}

	// MARK: - General

	fileprivate func prepareForClosePhotoBrowser() {
		// Gesture
		applicationWindow.removeGestureRecognizer(panGesture)
		autoHide = false

		// Controls
		NSObject.cancelPreviousPerformRequests(withTarget: self)
	}

	fileprivate func dismissPhotoBrowserAnimated(_ animated: Bool) {
		modalTransitionStyle = .crossDissolve
		delegate?.photoBrowser?(self, willDismissAtPageIndex: currentPageIndex)
		dismiss(animated: animated, completion: { [weak self] in
			guard let sself = self else { return }
			sself.delegate?.photoBrowser?(sself, didDismissAtPageIndex: sself.currentPageIndex)
		})
	}

	fileprivate func getImageFromView(_ view: UIView) -> UIImage {
		UIGraphicsBeginImageContext(view.frame.size)
		if let context = UIGraphicsGetCurrentContext() {
			view.layer.render(in: context)
		}
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
    
	fileprivate func customToolbarButtonImage(_ image: UIImage, imageSelected selectedImage: UIImage, action: Selector) -> UIButton {
		let button = UIButton(type: .custom)
		button.setBackgroundImage(image, for: .normal)
		button.setBackgroundImage(selectedImage, for: .disabled)
		button.addTarget(self, action: action, for: .touchUpInside)
		button.contentMode = .center
		button.frame = CGRect(x: 0, y: 0, width: image.size.width / 2, height: image.size.height / 2)
		return button
	}

	fileprivate func topviewController() -> UIViewController! {
		var topviewController = UIApplication.shared.keyWindow?.rootViewController
		while topviewController?.presentedViewController != nil {
			topviewController = topviewController?.presentedViewController
		}
		return topviewController
	}

	// MARK: - Animation

	fileprivate func rotateImageToCurrentOrientation(_ image: UIImage) -> UIImage? {
		let o = UIApplication.shared.statusBarOrientation
		if UIInterfaceOrientationIsLandscape(o) {
			let orientation = o == .landscapeLeft ? UIImageOrientation.left : UIImageOrientation.right

			guard let cgImage = image.cgImage else {
				return nil
			}

			let rotatedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
			return rotatedImage
		}
		return image
	}

	fileprivate func performPresentAnimation() {
		view.alpha = 0.0
		pagingScrollView.alpha = 0.0

		if nil != senderViewForAnimation {
			let imageFromView = scaleImage != nil ? scaleImage! : getImageFromView(senderViewForAnimation)

//			imageFromView = rotateImageToCurrentOrientation(imageFromView!)

			senderViewOriginalFrame = senderViewForAnimation.superview?.convert(senderViewForAnimation.frame, to: nil)

			let screenBound = UIScreen.main.bounds
			let screenWidth = screenBound.size.width
			let screenHeight = screenBound.size.height

			let fadeView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
			fadeView.backgroundColor = UIColor.clear
			applicationWindow.addSubview(fadeView)

            let resizableImageView = UIImageView()
			resizableImageView.frame = senderViewOriginalFrame
			resizableImageView.clipsToBounds = true
			resizableImageView.contentMode = .scaleAspectFit
			resizableImageView.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha: 1)
			applicationWindow.addSubview(resizableImageView)
			senderViewForAnimation?.isHidden = true

			typealias Completion = () -> ()
			let completion: Completion = { [weak self] in
				guard let sself = self else { return }
				sself.view.alpha = 1.0
				sself.pagingScrollView.alpha = 1.0
				resizableImageView.backgroundColor = UIColor(white: sself.useWhiteBackgroundColor ? 1 : 0, alpha: 1)
				fadeView.removeFromSuperview()
				resizableImageView.removeFromSuperview()
			}
			UIView.animate(withDuration: TimeInterval(animationDuration), animations: { () -> Void in
				fadeView.backgroundColor = self.useWhiteBackgroundColor ? UIColor.white : UIColor.black
			})

//			let scaleFactor =  imageFromView.size.width / screenWidth
//            let y = (screenHeight / 2) - (((imageFromView.size.height) / scaleFactor) / 2)
//            let h = (imageFromView.size.height) / scaleFactor
//			var finalImageViewFrame = CGRect(x: 0, y: y, width: screenWidth, height: h)
            let finalImageViewFrame = UIScreen.main.bounds
            let wr = imageFromView.size.width / finalImageViewFrame.width
            let hr = imageFromView.size.height / finalImageViewFrame.height
            let minLenght = min(imageFromView.size.width, imageFromView.size.height)
            var length = finalImageViewFrame.width
            if wr > hr {
                length = minLenght / wr
            } else {
                length = minLenght / hr
            }
            resizableImageView.image = resizeImage(image: imageFromView, newWidth: length)

			if usePopAnimation {
				animateView(resizableImageView, toFrame: finalImageViewFrame, completion: completion)
			} else {
				UIView.animate(withDuration: TimeInterval(animationDuration), animations: { () -> Void in
					resizableImageView.layer.frame = finalImageViewFrame
					}, completion: { (b) -> Void in
					if b {
						completion()
					}
				})
			}
		} else {
			view.alpha = 1.0
			pagingScrollView.alpha = 1.0
		}
	}
    
    private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

	fileprivate func performCloseAnimationWithScrollView(_ scrollView: SSZoomingScrollView) {
		let fadeAlpha = 1 - fabs(scrollView.frame.origin.y) / scrollView.frame.size.height

		var imageFromView = scrollView.photo?.underlyingImage()
		if imageFromView == nil {
			imageFromView = scrollView.photo?.placeholderImage()
		}

		typealias Completion = () -> ()
		let completion: Completion = { [weak self] in
			guard let sself = self else { return }
			sself.senderViewForAnimation?.isHidden = false
			sself.senderViewForAnimation = nil
			sself.scaleImage = nil

			sself.prepareForClosePhotoBrowser()
			sself.dismissPhotoBrowserAnimated(false)
		}

		if imageFromView == nil {
			completion()
			return
		}

		// imageFromView = [self rotateImageToCurrentOrientation:imageFromView]

		let screenBound = UIScreen.main.bounds
		let screenWidth = screenBound.size.width
		let screenHeight = screenBound.size.height

		let scaleFactor = (imageFromView?.size.width)! / screenWidth

		let fadeView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
		fadeView.backgroundColor = self.useWhiteBackgroundColor ? UIColor.white : UIColor.black
		fadeView.alpha = fadeAlpha
		applicationWindow.addSubview(fadeView)

		let resizableImageView = UIImageView(image: imageFromView)
		resizableImageView.frame = imageFromView != nil ? CGRect(x: 0, y: (screenHeight / 2) - (((imageFromView?.size.height)! / scaleFactor) / 2) + scrollView.frame.origin.y, width: screenWidth, height: (imageFromView?.size.height)! / scaleFactor) : CGRect.zero
		resizableImageView.contentMode = UIViewContentMode.scaleAspectFit
		resizableImageView.backgroundColor = UIColor.clear
		resizableImageView.clipsToBounds = true
		applicationWindow.addSubview(resizableImageView)
		self.view.isHidden = true

		let bcompletion: Completion = { [weak self] in
			guard let sself = self else { return }
			sself.senderViewForAnimation?.isHidden = false
			sself.senderViewForAnimation = nil
			sself.scaleImage = nil

			fadeView.removeFromSuperview()
			resizableImageView.removeFromSuperview()

			sself.prepareForClosePhotoBrowser()
			sself.dismissPhotoBrowserAnimated(false)
		}
		UIView.animate(withDuration: TimeInterval(animationDuration), animations: { () -> Void in
			fadeView.alpha = 0
			self.view.backgroundColor = UIColor.clear
		})

		if usePopAnimation {
			let edge = UIScreen.main.bounds.height
			let fromFrame = senderViewOriginalFrame ?? resizableImageView.frame.offsetBy(dx: 0, dy: edge)
			animateView(resizableImageView, toFrame: fromFrame, completion: bcompletion)
		} else {
			UIView.animate(withDuration: TimeInterval(animationDuration), animations: { () -> Void in
				resizableImageView.layer.frame = self.senderViewOriginalFrame
				}, completion: { (b) -> Void in
				if b {
					bcompletion()
				}
			})
		}
	}

	// MARK: - Layout

	fileprivate func performLayout() {

		performingLayout = true
		let photosCount = numberOfPhotos()

		visiblePages?.removeAll(keepingCapacity: false)
		recycledPages?.removeAll(keepingCapacity: false)

		if displayToolbar {
			view.addSubview(toolbar)
		} else {
			toolbar.removeFromSuperview()
		}

		if displayDoneButton && self.navigationController?.navigationBar == nil {
			view.addSubview(doneButton)
		}

		let fixedLeftSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
		fixedLeftSpace.width = 32

		let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

		var items = [UIBarButtonItem]()

		if displayActionButton {
			items.append(fixedLeftSpace)
		}

		items.append(flexSpace)

		if photosCount > 1 && displayArrowButton {
			items.append(previousButton)
		}

		if displayCounterLabel {
			items.append(flexSpace)
			items.append(counterButton)
		}

		items.append(flexSpace)

		if photosCount > 1 && displayArrowButton {
			items.append(nextButton)
		}

		items.append(flexSpace)

		if displayActionButton {
			items.append(actionButton)
		}

		toolbar.items = items

		updateToolbar()

		pagingScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)
		tilePages()
		performingLayout = false

		if !disableVerticalSwipe {
			view.addGestureRecognizer(panGesture)
		}
	}

	// MARK: - Toolbar
	fileprivate func updateToolbar() {
		// Counter
		let count = numberOfPhotos()
		if count > 1 {
			counterLabel.text = "\(currentPageIndex + 1) " + SSPhotoBrowserLocalizedStrings("of") + " \(count)"
		} else {
			counterLabel.text = nil
		}

		// Buttons
		previousButton.isEnabled = currentPageIndex > 0
		nextButton.isEnabled = currentPageIndex < count - 1
	}

	fileprivate func jumpToPageAtIndex(_ index: Int) {
		// Change page
		let count = numberOfPhotos()
		if index < count {
			let pageFrame = frameForPageAtIndex(index)

			if arrowButtonsChangePhotosAnimated {
				pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - PADDING, y: 0), animated: true)
			} else {
				pagingScrollView.contentOffset = CGPoint(x: pageFrame.origin.x - PADDING, y: 0)
				updateToolbar()
			}
		}

		// Update timer to give more time
		hideControlsAfterDelay()
	}

	func gotoPreviousPage() {
		jumpToPageAtIndex(currentPageIndex - 1)
	}

	func gotoNextPage() {
		jumpToPageAtIndex(currentPageIndex + 1)
	}

	// MARK: - Frame Calculations

	fileprivate func isLandscape(_ orientation: UIInterfaceOrientation) -> Bool
	{
		return UIInterfaceOrientationIsLandscape(orientation)
	}

	fileprivate func frameForToolbarAtOrientation(_ orientation: UIInterfaceOrientation) -> CGRect {
		var height: CGFloat = 44

		if isLandscape(orientation) {
			height = 32
		}

		return CGRect(x: 0, y: view.bounds.size.height - height, width: view.bounds.size.width, height: height)
	}

	fileprivate func frameForDoneButtonAtOrientation(_ orientation: UIInterfaceOrientation) -> CGRect {
        if let rect = doneButtonFrame { return rect }
		let screenBound = view.bounds
		let screenWidth = screenBound.size.width
		return CGRect(x: screenWidth - 75, y: 30, width: 55, height: 26)
	}

	fileprivate func frameForCaptionView(_ captionView: SSCaptionView, atIndex index: Int) -> CGRect {
		let pageFrame = frameForPageAtIndex(index)

		let captionSize = captionView.sizeThatFits(CGSize(width: pageFrame.size.width, height: 0))

		let captionFrame = CGRect(x: pageFrame.origin.x, y: pageFrame.size.height - captionSize.height - (toolbar.superview != nil ? toolbar.frame.size.height : 0), width: pageFrame.size.width, height: captionSize.height)

		return captionFrame
	}

	fileprivate func frameForPageAtIndex(_ index: Int) -> CGRect {
		// We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
		// landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
		// view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
		// because it has a rotation transform applied.
		let bounds = pagingScrollView.bounds
		var pageFrame = bounds
		pageFrame.size.width -= (2 * PADDING)
		pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + PADDING
		return pageFrame
	}

	fileprivate func contentSizeForPagingScrollView() -> CGSize {
		// We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
		let bounds = pagingScrollView.bounds
		let count = numberOfPhotos()
		return CGSize(width: bounds.size.width * CGFloat(count), height: bounds.size.height)
	}
	fileprivate func frameForPagingScrollView() -> CGRect {
		var frame = view.bounds
		frame.origin.x -= PADDING
		frame.size.width += 2 * PADDING
		return frame
	}

	fileprivate func contentOffsetForPageAtIndex(_ index: Int) -> CGPoint {
		let pageWidth = pagingScrollView.bounds.size.width
		let newOffset = CGFloat(index) * pageWidth
		return CGPoint(x: newOffset, y: 0)
	}

	// MARK: - Paging

	fileprivate func pageDisplayedAtIndex(_ index: Int) -> SSZoomingScrollView! {
		for page in visiblePages {
			if PAGE_INDEX(page) == index {
				return page
			}
		}
		return nil
	}

	fileprivate func pageDisplayingPhoto(_ photo: SSPhoto) -> SSZoomingScrollView! {
		var aPage: SSZoomingScrollView!
		for page in visiblePages {
			if let bPhoto = page.photo {
				if bPhoto == photo {
					aPage = page
				}
			}
		}
		return aPage
	}

	fileprivate func isDisplayingPageForIndex(_ index: Int) -> Bool {
		for page in visiblePages {
			let pageIndex = PAGE_INDEX(page)
			if pageIndex == index {
				return true
			}
		}
		return false
	}

	fileprivate func configurePage(_ page: SSZoomingScrollView, forIndex index: Int) {
		page.frame = frameForPageAtIndex(index)
		page.tag = PAGE_INDEX_TAG_OFFSET + index
		page.setAPhoto(photoAtIndex(index))
		page.photo?.progressUpdateBlock = { [weak page]
			(progress) -> Void in
			DispatchQueue.main.async(execute: { () -> Void in
				page?.setProgress(progress, forPhoto: page?.photo)
			})
		}
	}

	fileprivate func dequeueRecycledPage() -> SSZoomingScrollView! {
		let page = recycledPages.first
		if page != nil {
			recycledPages.remove(page!)
		}
		return page
	}

	fileprivate func didStartViewingPageAtIndex(_ index: Int) {
		// Load adjacent images if needed and the photo is already
		// loaded. Also called after photo has been loaded in background
		let currentPhoto = photoAtIndex(index)
		if currentPhoto.underlyingImage() != nil {
			// photo loaded so load ajacent now
			loadAdjacentPhotosIfNecessary(currentPhoto)
		}
		delegate?.photoBrowser?(self, didShowPhotoAtIndex: index)
	}

	fileprivate func tilePages() {
		let visibleBounds = pagingScrollView.bounds
		var iFirstIndex = Int(floor((visibleBounds.minX + PADDING * 2) / visibleBounds.width))
		var iLastIndex = Int(floor((visibleBounds.maxX - PADDING * 2 - 1) / visibleBounds.width))
		let phototCount = numberOfPhotos()
		if iFirstIndex < 0 {
			iFirstIndex = 0
		}
		if iFirstIndex > phototCount - 1 {
			iFirstIndex = phototCount - 1
		}
		if iLastIndex < 0 {
			iLastIndex = 0
		}
		if iLastIndex > phototCount - 1 {
			iLastIndex = phototCount - 1
		}
		// Recycle no longer needed pages
		var pageIndex: Int = 0
		for page in visiblePages {
			pageIndex = PAGE_INDEX(page)
			if pageIndex < iFirstIndex || pageIndex > iLastIndex {
				recycledPages.insert(page)
				page.prepareForReuse()
				page.removeFromSuperview()
			}
		}
		visiblePages = visiblePages.subtracting(recycledPages)

		var pages = Set<SSZoomingScrollView>()
		if recycledPages.count > 2 {
			let array = Array(recycledPages)
			pages.insert(array[0])
			pages.insert(array[1])
		} else {
			pages = recycledPages
		} // Only keep 2 recycled pages
		recycledPages = pages

		// Add missing pages

		for index in iFirstIndex ... iLastIndex {
			if !isDisplayingPageForIndex(index) {
				let page = SSZoomingScrollView(aPhotoBrowser: self)
				page.backgroundColor = UIColor.clear
				page.isOpaque = true
				configurePage(page, forIndex: index)
				visiblePages.insert(page)
				pagingScrollView.addSubview(page)

				if let captionView = captionViewForPhotoAtIndex(index) {
					captionView.frame = frameForCaptionView(captionView, atIndex: index)
					pagingScrollView.addSubview(captionView)
					page.captionView = captionView
				}
			}
		}
	}

	// MARK: - Buttons
	func doneButtonPressed() {
		if senderViewForAnimation != nil && currentPageIndex == initalPageIndex {
			let scrollView = pageDisplayedAtIndex(currentPageIndex)
			performCloseAnimationWithScrollView(scrollView!)
		}
		else {
			senderViewForAnimation?.isHidden = false
			prepareForClosePhotoBrowser()
			dismissPhotoBrowserAnimated(true)
		}
	}

	func actionButtonPressed(_ sender: AnyObject) {
		let photo = photoAtIndex(currentPageIndex)
		let count = self.numberOfPhotos()
		if count > 0 && photo.underlyingImage() != nil {
			if actionButtonTitles.count == 0 {
				if let image = photo.underlyingImage() {
					var activityItems: [AnyObject] = [image]
					if let caption = photo.caption() {
						activityItems.append(caption as AnyObject)
					}

					activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

					activityViewController.completionWithItemsHandler = { [weak self]
						(activityType, completed, returnedItems, activityError) -> Void in
						guard let sself = self else { return }
						sself.hideControlsAfterDelay()
						if activityType == .saveToCameraRoll  {
							NotificationCenter.default.post(name: Notification.Name(rawValue: UIApplicationSaveImageToCameraRoll), object: sself)
						}
						sself.activityViewController = nil
					}
					present(activityViewController, animated: true, completion: nil)
				}
			} else {
				// Action sheet
				actionsSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
				for (index, atitle) in actionButtonTitles.enumerated() {
					let action = UIAlertAction(title: atitle, style: UIAlertActionStyle.default, handler: { [weak self]
						(aAction) -> Void in
						guard let sself = self else { return }
						sself.actionsSheet = nil
						sself.delegate?.photoBrowser?(sself, didDismissActionSheetWithButtonIndex: index, photoIndex: sself.currentPageIndex)
						sself.hideControlsAfterDelay()
					})
					actionsSheet.addAction(action)
				}
				let action = UIAlertAction(title: SSPhotoBrowserLocalizedStrings("Cancel"), style: UIAlertActionStyle.cancel, handler: { [weak self]
					(aAction) -> Void in
					guard let sself = self else { return }
					sself.actionsSheet = nil
					sself.hideControlsAfterDelay()
				})
				actionsSheet.addAction(action)
				present(actionsSheet, animated: true, completion: nil)
			}
		}
		setControlsHidden(false, animated: true, permanent: true)
	}

	// MARK: - pop Animation

	fileprivate func animateView(_ view: UIView, toFrame frame: CGRect, completion: (() -> ())!) {

		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions(), animations: {
			view.frame = frame
		}) { (b) in
			completion?()
		}
	}

}

extension SSImageBrowser {

	typealias CancelableTask = (_ cancel: Bool) -> Void

	func delay(_ time: TimeInterval, work: @escaping ()->()) -> CancelableTask? {

		var finalTask: CancelableTask?

		let cancelableTask: CancelableTask = { cancel in
			if cancel {
				finalTask = nil // key
			} else {
				DispatchQueue.main.async(execute: work)
			}
		}

		finalTask = cancelableTask

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
			if let task = finalTask {
				task(false)
			}
		}

		return finalTask
	}

	func cancel(_ cancelableTask: CancelableTask?) {
		cancelableTask?(true)
	}
}
