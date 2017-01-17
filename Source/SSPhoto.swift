//
//  SSPhoto.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit
import Photos

public final class SSPhoto: NSObject {
	public var aCaption: String?
	public var photoURL: URL?
	public var progressUpdateBlock: SSProgressUpdateBlock?
	public var aPlaceholderImage: UIImage?

	fileprivate var aUnderlyingImage: UIImage?
	fileprivate var loadingInProgress: Bool?
	public var photoPath: String?
	public var asset: PHAsset?
	public var targetSize: CGSize?
	fileprivate var requestId: PHImageRequestID?
	fileprivate var _task: URLSessionTask?

	convenience public init(image: UIImage) {
		self.init()
		aUnderlyingImage = image
	}

	convenience public init(filePath: String) {
		self.init()
		photoPath = filePath
	}

	convenience public init(url: URL) {
		self.init()
		photoURL = url
	}

	convenience public init(aAsset: PHAsset, aTargetSize: CGSize! = nil) {
		self.init()
		asset = aAsset
		targetSize = aTargetSize
	}

	override init() {
		super.init()
		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "stopAllRequest"), object: nil, queue: OperationQueue.main) { [weak self](_) -> Void in
			self?.cancelRequest()
		}
	}

	deinit {
		cancelRequest()
	}

	func cancelRequest() {
		if let id = requestId {
			PHImageManager.default().cancelImageRequest(id)
		}
	}
}
// MARK: - NSURLSessionDelegate
extension SSPhoto: URLSessionDownloadDelegate {
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		let downloadedImage = UIImage(data: try! Data(contentsOf: location))
		aUnderlyingImage = downloadedImage
		DispatchQueue.main.async { self.imageLoadingComplete() }
	}
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
		progressUpdateBlock?(progress)
	}
}
// MARK: - Class Method
extension SSPhoto {

	public class func photoWithImage(_ image: UIImage) -> SSPhoto {
		return SSPhoto(image: image)
	}

	public class func photoWithFilePath(_ path: String) -> SSPhoto {
		return SSPhoto(filePath: path)
	}

	public class func photoWithURL(_ url: URL) -> SSPhoto {
		return SSPhoto(url: url)
	}

	public class func photosWithImages(_ imagesArray: [UIImage]) -> [SSPhoto] {
		var photos = [SSPhoto]()
		for image in imagesArray {
			photos.append(SSPhoto(image: image))
		}
		return photos
	}

	public class func photosWithFilePaths(_ pathsArray: [String]) -> [SSPhoto] {
		var photos = [SSPhoto]()
		for path in pathsArray {
			photos.append(SSPhoto(filePath: path))
		}
		return photos
	}

	public class func photosWithURLs(_ urlsArray: [URL]) -> [SSPhoto] {
		var photos = [SSPhoto]()
		for url in urlsArray {
			photos.append(SSPhoto(url: url))
		}
		return photos
	}

	public class func photosWithAssets(_ assets: [PHAsset], targetSize: CGSize! = nil) -> [SSPhoto] {
		var photos = [SSPhoto]()
		for asset in assets {
			photos.append(SSPhoto(aAsset: asset, aTargetSize: targetSize))
		}
		return photos
	}
}

// MARK: - SSPhotoProtocol
public func == (lhs: SSPhoto, rhs: SSPhoto) -> Bool {
	return lhs.hashValue == rhs.hashValue
}

extension SSPhoto {

	public func underlyingImage() -> UIImage! {
		return aUnderlyingImage
	}

	fileprivate func createDownloadTask(_ url: URL) {
		_task?.cancel()
		let downloadRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
		let session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
		_task = session.downloadTask(with: downloadRequest)
		_task?.resume()
	}

	public func loadUnderlyingImageAndNotify() {
		loadingInProgress = true
		if aUnderlyingImage != nil {
			imageLoadingComplete()
		} else {
			if let _ = photoPath {
                DispatchQueue.global(qos: .default).async {
                    self.loadImageFromFileAsync()
                }
				
			} else if let url = photoURL {

                DispatchQueue.global(qos: .userInitiated).async {
					self.createDownloadTask(url)
				}
			} else if let photo = asset {
				var size = CGSize(width: CGFloat(photo.pixelWidth), height: CGFloat(photo.pixelHeight))
				if let asize = targetSize {
					size = asize
				}
				weak var wsekf: SSPhoto! = self

				let progressBlock: PHAssetImageProgressHandler = { (value, error, stop, info) -> Void in
					DispatchQueue.main.async(execute: { () -> Void in
						wsekf.progressUpdateBlock?(CGFloat(value))
					})
				}
				DispatchQueue.global(qos: .default).async {
					wsekf.requestId = photo.imageWithSize(size, progress: progressBlock, done: { (image) -> () in
						DispatchQueue.main.async(execute: { () -> Void in
							wsekf.aUnderlyingImage = image
							wsekf.imageLoadingComplete()
						})
					})
				}
			}
		}
	}

	public func unloadUnderlyingImage() {
		loadingInProgress = false
		if aUnderlyingImage != nil && (photoPath != nil || photoURL != nil) {
			aUnderlyingImage = nil
		}
		cancelRequest()
	}

	public func caption() -> String? {
		return aCaption
	}

	public func placeholderImage() -> UIImage? {
		return aPlaceholderImage
	}
}

// MARK: - Async Loading
extension SSPhoto {
	func decodedImageWithImage(_ image: UIImage) -> UIImage? {
		if let _ = image.images {
			return image
		}

		let imageRef = image.cgImage
		let imageSize = CGSize(width: CGFloat((imageRef?.width)!), height: CGFloat((imageRef?.height)!))
		let imageRect = (CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		var bitmapInfo = imageRef?.bitmapInfo

		let infoMask = bitmapInfo?.intersection(CGBitmapInfo.alphaInfoMask)

		let alphaNone = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
		let alphaNoneSkipFirst = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
		let alphaNoneSkipLast = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
		let anyNonAlpha = infoMask == alphaNone ||
		infoMask == alphaNoneSkipFirst ||
		infoMask == alphaNoneSkipLast

		// CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.

		if (infoMask == alphaNone && colorSpace.numberOfComponents > 1)
		{
			// Unset the old alpha info.
			let newBitmapInfoRaw = (bitmapInfo?.rawValue)! & ~CGBitmapInfo.alphaInfoMask.rawValue

			// Set noneSkipFirst.
			bitmapInfo = CGBitmapInfo(rawValue: (newBitmapInfoRaw | alphaNoneSkipFirst.rawValue))
		}
		// Some PNGs tell us they have alpha but only 3 components. Odd.
		else if (!anyNonAlpha && colorSpace.numberOfComponents == 3)
		{
			// Unset the old alpha info.
			let newBitmapInfoRaw = (bitmapInfo?.rawValue)! & ~CGBitmapInfo.alphaInfoMask.rawValue
//            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
			bitmapInfo = CGBitmapInfo(rawValue: newBitmapInfoRaw | CGImageAlphaInfo.premultipliedFirst.rawValue)
		}

		// It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
		let context = CGContext(data: nil, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: 0, space: colorSpace, bitmapInfo: (bitmapInfo?.rawValue)!)

		// If failed, return undecompressed image
		if context == nil {
			return image
		}

		context?.draw(imageRef!, in: imageRect)
		guard let decompressedImageRef = context?.makeImage() else {
			return nil
		}

		let decompressedImage = UIImage(cgImage: decompressedImageRef, scale: image.scale, orientation: image.imageOrientation)
		return decompressedImage
	}

	func loadImageFromFileAsync() {
		autoreleasepool { () -> () in
			if let path = photoPath, let img = UIImage(contentsOfFile: path) {
				aUnderlyingImage = img
			} else {
				if let image = aUnderlyingImage, let img = decodedImageWithImage(image) {
					aUnderlyingImage = img
				}
			}
			DispatchQueue.main.async(execute: { () -> Void in
				self.imageLoadingComplete()
			})
		}
	}

	func imageLoadingComplete() {
		loadingInProgress = false
		NotificationCenter.default.post(name: Notification.Name.SSPhotoLoadingDidEnd, object: self)
	}
}

public extension PHAsset {

	public var identifier: String {
		return URL(string: self.localIdentifier)?.pathComponents[0] ?? ""
	}

	public func imageWithSize(_ size: CGSize, progress: PHAssetImageProgressHandler!, done: @escaping (UIImage!) -> ()) -> PHImageRequestID! {
		let cache = URLCache.shared
		let key = identifier + "_\(size.width)x\(size.height)"
		guard let url = URL(string: "https://\(key)") else { return nil }
		let request = URLRequest(url: url)
		if let resp = cache.cachedResponse(for: request), let img = UIImage(data: resp.data) {
			done(img)
			return nil
		}
		let manager = PHImageManager.default()
		let option = PHImageRequestOptions()
		option.isSynchronous = false
		option.isNetworkAccessAllowed = true
		option.normalizedCropRect = CGRect(origin: CGPoint.zero, size: size)
		option.resizeMode = .exact
		option.progressHandler = progress
		option.deliveryMode = .highQualityFormat
		option.version = .original

		return manager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: { (result, info) -> Void in
			if let img = result {
				let urlresp = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
				if let data = UIImageJPEGRepresentation(img, 1) {
					let resp = CachedURLResponse(response: urlresp, data: data)
					cache.storeCachedResponse(resp, for: request)
				}
			}
			done(result)
		})
	}
}
