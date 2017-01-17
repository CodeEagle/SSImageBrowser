//
//  SSCaptionView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit

public final class SSCaptionView: UIView {
	var photo: SSPhoto?
	private var labelPadding: CGFloat { return 10 }
    private lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: self.labelPadding, y: 0, width: self.bounds.size.width - self.labelPadding * 2, height: self.bounds.size.height))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.isOpaque = false
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 3
        label.textColor = UIColor.white
        label.shadowColor = UIColor(white: 0, alpha: 0.5)
        label.shadowOffset = CGSize(width: 0, height: 1)
        label.font = UIFont.systemFont(ofSize: 17)
        label.text = ""
        return label
    }()

	convenience init(aPhoto: SSPhoto) {
		let screenBound = UIScreen.main.bounds
		var screenWidth = screenBound.size.width
		let orientation = UIDevice.current.orientation
		if orientation == .landscapeLeft ||
		orientation == .landscapeRight {
			screenWidth = screenBound.size.height
		}
		self.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
		photo = aPhoto
		isOpaque = false
		setBackground()
		setupCaption()
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	open override func layoutSubviews() {
		super.layoutSubviews()
		if let view = viewWithTag(101) {
			let len = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
			view.frame = CGRect(x: 0, y: -100, width: len, height: 130 + 100)
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
	private func setupCaption() {
		if let cap = photo?.caption() { label.text = cap }
		addSubview(label)
	}

	/**
	 Override -sizeThatFits: and return a CGSize specifying the height of your
	 custom caption view. With width property is ignored and the caption is displayed
	 the full width of the screen


	 :param: size CGSize

	 :returns: CGSize
	 */
	open override func sizeThatFits(_ size: CGSize) -> CGSize {
		if label.text == nil || label.text?.isEmpty == true { return .zero }
		var maxHeight: CGFloat = 9999
		if label.numberOfLines > 0 {
			maxHeight = label.font.lineHeight * CGFloat(label.numberOfLines)
		}

		let text = label.text!
		let width = size.width - labelPadding * 2
		let font = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)

		let attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])

        let size = CGSize(width: width, height: maxHeight)
		let rect = attributedText.boundingRect(with: size , options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

		let textSize = rect.size

		return CGSize(width: size.width, height: textSize.height + labelPadding * 2)
	}
    
    private func setBackground() {
        let len = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let fadeView = UIView(frame: CGRect(x: 0, y: -100, width: len, height: 130 + 100)) // Static width, autoresizingMask is not working
        fadeView.tag = 101
        let gradient = CAGradientLayer()
        gradient.frame = fadeView.bounds
        gradient.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.8).cgColor]
        fadeView.layer.insertSublayer(gradient, at: 0)
        fadeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(fadeView)
    }
}


