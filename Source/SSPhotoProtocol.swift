//
//  SSPhotoProtocol.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import Foundation

//public protocol SSPhotoProtocol: class, Hashable {
//    
//    /**
//    Return underlying UIImage to be displayed
//    Return nil if the image is not immediately available (loaded into memory, preferably
//    already decompressed) and needs to be loaded from a source (cache, file, web, etc)
//    IMPORTANT: You should *NOT* use this method to initiate
//    fetching of images from any external of source. That should be handled
//    in -loadUnderlyingImageAndNotify: which may be called by the photo browser if this
//    methods returns nil.
//
//    
//    :returns: UIImage
//    */
//    func underlyingImage()->UIImage!
//    
//    /**
//    Called when the browser has determined the underlying images is not
//    already loaded into memory but needs it.
//    You must load the image asyncronously (and decompress it for better performance).
//    See IDMPhoto object for an example implementation.
//    When the underlying UIImage is loaded (or failed to load) you should post the following
//    notification:
//    
//    NSNotificationCenter.defaultCenter().postNotificationName(SSPHOTO_LOADING_DID_END_NOTIFICATION, object: self)
//
//    */
//    func loadUnderlyingImageAndNotify()
//    
//    /**
//    This is called when the photo browser has determined the photo data
//    is no longer needed or there are low memory conditions
//    You should release any underlying (possibly large and decompressed) image data
//    as long as the image can be re-loaded (from cache, file, or URL)
//
//    */
//    func unloadUnderlyingImage()
//    
//    /**
//    Return a caption string to be displayed over the image
//    Return nil to display no caption
//
//    
//    :returns: String?
//    */
//    func caption()->String?
//    
//    /**
//    Return placeholder UIImage to be displayed while loading underlyingImage
//    Return nil if there is no placeholder
//
//    
//    :returns: UIImage?
//    */
//    func placeholderImage() -> UIImage?
//    
//    
//    
//    static func photoWithImage(image: UIImage) -> Self
//    
//    static func photoWithFilePath(path: String) -> Self
//    
//    static func photoWithURL(url: NSURL) -> Self
//    
//    static func photosWithImages(imagesArray: [UIImage]) -> [Self]
//    
//    static func photosWithFilePaths(pathsArray: [String]) -> [Self]
//    
//    static func photosWithURLs(urlsArray: [NSURL]) -> [Self]
//    
//    var progressUpdateBlock: SSProgressUpdateBlock! { get set }
//    var photoURL: NSURL! { get set }
//}