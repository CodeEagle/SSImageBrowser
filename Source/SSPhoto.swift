//
//  SSPhoto.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit
import SDWebImage
import Photos
public final class SSPhoto: NSObject{
    public var aCaption: String!
    public var photoURL: NSURL!
    public var progressUpdateBlock: SSProgressUpdateBlock!
    public var aPlaceholderImage: UIImage!
    
    private var aUnderlyingImage: UIImage!
    private var loadingInProgress: Bool!
    public var  photoPath: String!
    public var asset: PHAsset!
    public var targetSize: CGSize!
    private var requestId: PHImageRequestID!
    
    convenience public init(image: UIImage) {
        self.init()
        aUnderlyingImage = image
    }
    
    convenience public init(filePath: String) {
        self.init()
        photoPath = filePath
    }
    
    convenience public init(url: NSURL) {
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
        weak var wself: SSPhoto! = self
        NSNotificationCenter.defaultCenter().addObserverForName("stopAllRequest", object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
            wself.cancelRequest()
        }
    }
    
    deinit {
        cancelRequest()
    }
    
    func cancelRequest() {
        if let id = requestId {
            PHImageManager.defaultManager().cancelImageRequest(id)
        }
    }
}
// MARK: - NSURLSessionDelegate
extension SSPhoto: NSURLSessionDownloadDelegate{
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let downloadedImage = UIImage(data: NSData(contentsOfURL: location)!)
        self.aUnderlyingImage = downloadedImage
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.imageLoadingComplete()
        })
    }
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten)/CGFloat(totalBytesExpectedToWrite)
        progressUpdateBlock?(progress)
    }
}
// MARK: - Class Method
extension SSPhoto {
    
    public class func photoWithImage(image: UIImage) -> SSPhoto {
        return SSPhoto(image: image)
    }
    
    public class func photoWithFilePath(path: String) -> SSPhoto {
        return SSPhoto(filePath: path)
    }
    
    public class func photoWithURL(url: NSURL) -> SSPhoto {
        return SSPhoto(url: url)
    }
    
    public class func photosWithImages(imagesArray: [UIImage]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for image in imagesArray {
            photos.append(SSPhoto(image: image))
        }
        return photos
    }
    
    public class func photosWithFilePaths(pathsArray: [String]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for path in pathsArray {
            photos.append(SSPhoto(filePath: path))
        }
        return photos
    }
    
    public class func photosWithURLs(urlsArray: [NSURL]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for url in urlsArray {
            photos.append(SSPhoto(url: url))
        }
        return photos
    }
    
    public class func photosWithAssets(assets: [PHAsset], targetSize: CGSize! = nil) -> [SSPhoto] {
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
    public func loadUnderlyingImageAndNotify() {
        loadingInProgress = true
        if aUnderlyingImage != nil {
            imageLoadingComplete()
        }else{
            if let path = photoPath {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    self.loadImageFromFileAsync()
                })
            } else if let url = photoURL {
                let key = "\(url.hash)"
                
                let CacheCenter = SDImageCache.sharedImageCache()
                if let cache = CacheCenter.imageFromDiskCacheForKey(key) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                        self.aUnderlyingImage = cache
                        self.imageLoadingComplete()
                    }
                    return
                }
                SDWebImageDownloader.sharedDownloader().downloadImageWithURL(url, options: SDWebImageDownloaderOptions.ContinueInBackground, progress: { (read, total) -> Void in
                    let progress = CGFloat(read)/CGFloat(total)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        progressUpdateBlock?(progress)
                    })
                    }, completed: { (img, data, err, flag) -> Void in
                        if let image = img {
                            self.aUnderlyingImage = image
                            self.imageLoadingComplete()
                            CacheCenter.storeImage(image, forKey: key, toDisk: true)
                        }
                        
                })
                
            } else if let photo = asset {
                var size = CGSizeMake(CGFloat(photo.pixelWidth), CGFloat(photo.pixelHeight))
                if let asize = targetSize  {
                    size = asize
                }
                weak var wsekf: SSPhoto! = self
                
                let progressBlock: PHAssetImageProgressHandler = { (value, error, stop, info) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        wsekf.progressUpdateBlock?(CGFloat(value))
                    })
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    wsekf.requestId = photo.imageWithSize(size, progress: progressBlock , done: { (image) -> () in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            wsekf.aUnderlyingImage = image
                            wsekf.imageLoadingComplete()
                        })
                    })
                })
                
                
                
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
    func decodedImageWithImage(image:UIImage) -> UIImage? {
        if let gif = image.images {
            return image
        }
        
        let imageRef = image.CGImage
        let imageSize = CGSizeMake(CGFloat(CGImageGetWidth(imageRef)), CGFloat(CGImageGetHeight(imageRef)))
        let imageRect = (CGRectMake(0, 0, imageSize.width, imageSize.height))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGImageGetBitmapInfo(imageRef)
        
        let infoMask = bitmapInfo & CGBitmapInfo.AlphaInfoMask
        
        let alphaNone = CGBitmapInfo(CGImageAlphaInfo.None.rawValue)
        let alphaNoneSkipFirst = CGBitmapInfo(CGImageAlphaInfo.NoneSkipFirst.rawValue)
        let alphaNoneSkipLast = CGBitmapInfo(CGImageAlphaInfo.NoneSkipLast.rawValue)
        let anyNonAlpha = infoMask == alphaNone ||
            infoMask == alphaNoneSkipFirst ||
            infoMask == alphaNoneSkipLast
        
        // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
        
        if (infoMask == alphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1)
        {
            // Unset the old alpha info.
            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
            
            // Set noneSkipFirst.
            bitmapInfo |= alphaNoneSkipFirst
        }
            // Some PNGs tell us they have alpha but only 3 components. Odd.
        else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
        {
            // Unset the old alpha info.
            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
            bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        }
        
        // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
        let context = CGBitmapContextCreate(nil, Int(imageSize.width), Int(imageSize.width), CGImageGetBitsPerComponent(imageRef), 0, colorSpace, bitmapInfo)
        
        
        // If failed, return undecompressed image
        if context == nil {
            return image
        }
        
        CGContextDrawImage(context, imageRect, imageRef)
        let decompressedImageRef = CGBitmapContextCreateImage(context)
        
        let decompressedImage = UIImage(CGImage: decompressedImageRef, scale: image.scale, orientation: image.imageOrientation)
        return decompressedImage
    }
    
    func loadImageFromFileAsync() {
        autoreleasepool { () -> () in
            if let img = UIImage(contentsOfFile: photoPath) {
                aUnderlyingImage = img
            }else{
                if let img = decodedImageWithImage(aUnderlyingImage) {
                    aUnderlyingImage = img
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.imageLoadingComplete()
            })
        }
    }
    
    func imageLoadingComplete() {
        loadingInProgress = false
        NSNotificationCenter.defaultCenter().postNotificationName(SSPHOTO_LOADING_DID_END_NOTIFICATION, object: self)
    }
}


public extension PHAsset {
    
    public var identifier: String {
        return self.localIdentifier.pathComponents[0]
    }
    
    public func imageWithSize(size:CGSize, progress: PHAssetImageProgressHandler!, done:(UIImage!)->() ) -> PHImageRequestID! {
        let cache = SDImageCache.sharedImageCache()
        let key = self.identifier+"_\(size.width)x\(size.height)"
        if let img = cache.imageFromDiskCacheForKey(key) {
            done(img)
            return nil
        }
        let manager = PHImageManager.defaultManager()
        var option = PHImageRequestOptions()
        option.synchronous = false
        option.networkAccessAllowed = true
        option.normalizedCropRect = CGRect(origin: CGPointZero, size: size)
        option.resizeMode = .Exact
        option.progressHandler = progress
        option.deliveryMode = .HighQualityFormat
        option.version = .Original
        
        return manager.requestImageForAsset(self, targetSize: size, contentMode: .AspectFit, options: option, resultHandler: {(result, info)->Void in
            if let img = result {
                cache.storeImage(img, forKey: key, toDisk: true)
            }
            done(result)
        })
        
    }
    
    
}
