//
//  SSCaptionView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit

public class SSCaptionView: UIView {
    var photo: SSPhoto!
    
    private let labelPadding: CGFloat = 10
    private var label: UILabel!
    
    convenience init(aPhoto:SSPhoto) {
        let screenBound = UIScreen.mainScreen().bounds
        var screenWidth = screenBound.size.width
        let orientation = UIDevice.currentDevice().orientation
        if orientation == UIDeviceOrientation.LandscapeLeft ||
            orientation == UIDeviceOrientation.LandscapeRight {
                screenWidth = screenBound.size.height
        }
        self.init(frame: CGRectMake(0, 0, screenWidth, 44))
        photo = aPhoto
        self.opaque = false
        setBackground()
        setupCaption()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let view = self.viewWithTag(101) {
            view.frame = CGRectMake(0, -100, UIScreen.mainScreen().bounds.width, 130+100)
        }
        
    }
    /**
    To create your own custom caption view, subclass this view
    and override the following two methods (as well as any other
    UIView methods that you see fit):
    
    Override -setupCaption so setup your subviews and customise the appearance
    of your custom caption
    You can access the photo's data by accessing the _photo ivar
    If you need more data per photo then simply subclass IDMPhoto and return your
    subclass to the photo browsers -photoBrowser:photoAtIndex: delegate method
    
    */
    public func setupCaption() {
        
        label = UILabel(frame: CGRectMake(labelPadding, 0, self.bounds.size.width-labelPadding*2, self.bounds.size.height))
        label.autoresizingMask =  [.FlexibleWidth, .FlexibleHeight]
        label.opaque = false
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Center
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.numberOfLines = 3
        label.textColor = UIColor.whiteColor()
        label.shadowColor = UIColor(white: 0, alpha: 0.5)
        label.shadowOffset = CGSizeMake(0, 1)
        label.font = UIFont.systemFontOfSize(17)
        label.text = ""
        if let cap = photo?.caption() {
            label.text = cap
        }

        self.addSubview(label)
    }
    
    /**
    Override -sizeThatFits: and return a CGSize specifying the height of your
    custom caption view. With width property is ignored and the caption is displayed
    the full width of the screen

    
    :param: size CGSize
    
    :returns: CGSize
    */
    public override func sizeThatFits(size: CGSize) -> CGSize {
        if label.text == nil  {
            return CGSizeZero
        }
        
        if let b = label.text?.isEmpty  {
            if b {
                return CGSizeZero
            }
        }
        
        var maxHeight: CGFloat = 9999
        if label.numberOfLines > 0  {
            maxHeight = label.font.leading * CGFloat(label.numberOfLines)
        }
        
        
        let text = label.text!
        let width = size.width - labelPadding*2
        let font = label.font
        
        let attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
        
        let rect = attributedText.boundingRectWithSize(CGSizeMake(width, maxHeight), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
        
        let textSize = rect.size
        
        return CGSizeMake(size.width, textSize.height + labelPadding * 2)
    }
}

extension SSCaptionView {
    func setBackground() {
        let fadeView = UIView(frame:CGRectMake(0, -100, UIScreen.mainScreen().bounds.width, 130+100)) // Static width, autoresizingMask is not working
        fadeView.tag = 101
        let gradient = CAGradientLayer()
        gradient.frame = fadeView.bounds
        gradient.colors = [UIColor(white: 0, alpha: 0).CGColor,UIColor(white: 0, alpha: 0.8).CGColor]
        fadeView.layer.insertSublayer(gradient, atIndex: 0)
        fadeView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(fadeView)
    }
    
}
