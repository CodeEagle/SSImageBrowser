//
//  SSPhoto.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit

// This class models a photo/image and it's caption
// If you want to handle photos, caching, decompression
// yourself then you can simply ensure your custom data model
// conforms to SSPhotoProtocol

public final class SSPhoto: NSObject{
    public var aCaption: String!
    public var photoURL: NSURL!
    public var progressUpdateBlock: SSProgressUpdateBlock!
    public var aPlaceholderImage: UIImage!
    
    private var aUnderlyingImage: UIImage!
    private var loadingInProgress: Bool!
    public var  photoPath: String!
    private var downloadSession: NSURLSession!
    
    
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
    
    override init() {
        super.init()
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        downloadSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
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
            }else if let url = photoURL {
                let request = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 0)
                let getImageTask = downloadSession.downloadTaskWithRequest(request)
                getImageTask.resume()
            }
        }
        
    }
    
    public func unloadUnderlyingImage() {
        loadingInProgress = false
        if aUnderlyingImage != nil && (photoPath != nil || photoURL != nil) {
            aUnderlyingImage = nil
        }
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