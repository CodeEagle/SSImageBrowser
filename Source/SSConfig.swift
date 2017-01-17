//
//  SSConfig.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import Foundation

extension Notification.Name {
    static var SSPhotoLoadingDidEnd: Notification.Name { return Notification.Name(rawValue: "SSPHOTO_LOADING_DID_END_NOTIFICATION") }
}
let PADDING: CGFloat = 10
let PAGE_INDEX_TAG_OFFSET = 1000
public typealias SSProgressUpdateBlock = (CGFloat)->()

func PAGE_INDEX(_ page: SSZoomingScrollView)->Int {
    let index = page.tag - PAGE_INDEX_TAG_OFFSET
    return index
}
func SYSTEM_VERSION_EQUAL_TO(_ to:String) -> Bool{
    let ver = UIDevice.current.systemVersion as NSString
    return ver.compare(to, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedSame
}

func SYSTEM_VERSION_GREATER_THAN(_ to:String) -> Bool{
    let ver = UIDevice.current.systemVersion as NSString
    return ver.compare(to, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedDescending
}

func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_ to:String) -> Bool{
    let ver = UIDevice.current.systemVersion as NSString
    return ver.compare(to, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedAscending
}

func SYSTEM_VERSION_LESS_THAN(_ to:String) -> Bool{
    let ver = UIDevice.current.systemVersion as NSString
    return ver.compare(to, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending
}

func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_ to:String) -> Bool{
    let ver = UIDevice.current.systemVersion as NSString
    return ver.compare(to, options: NSString.CompareOptions.numeric) != ComparisonResult.orderedDescending
}

func SSPhotoBrowserLocalizedStrings(_ key: String) -> String{
    if let path = Bundle(for: SSImageBrowser.self).path(forResource: "IDMPBLocalizations", ofType: "bundle") {
        if let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: key)
        }
        
    }
    return key
}
