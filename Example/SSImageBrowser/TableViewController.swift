//
//  TableViewController.swift
//  SSImageBrowser
//
//  Created by LawLincoln on 15/7/12.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import SSImageBrowser
func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
}
class TableViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let tableViewFooter = UIView(frame: CGRectMake(0, 0, 320, 426 * 0.9 + 40))

		let buttonWithImageOnScreen1 = UIButton(type: .custom)
		buttonWithImageOnScreen1.frame = CGRectMake(15, 0, 640 / 2 * 0.9, 426 / 2 * 0.9)
		buttonWithImageOnScreen1.tag = 101
		buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen1.setImage(UIImage(named: "photo1m.jpg"), for: .normal)

		buttonWithImageOnScreen1.imageView?.contentMode = .scaleAspectFit
		buttonWithImageOnScreen1.backgroundColor = UIColor.black
		buttonWithImageOnScreen1.addTarget(self, action: #selector(TableViewController.buttonWithImageOnScreenPressed(buttonSender:)), for: .touchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen1)

		let buttonWithImageOnScreen2 = UIButton(type: .custom)
		buttonWithImageOnScreen2.frame = CGRectMake(15, 426 / 2 * 0.9 + 20, 640 / 2 * 0.9, 426 / 2 * 0.9)
		buttonWithImageOnScreen2.tag = 102
		buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen2.setImage(UIImage(named: "photo3m.jpg"), for: .normal)
		buttonWithImageOnScreen2.imageView?.contentMode = .scaleAspectFit
		buttonWithImageOnScreen2.backgroundColor = UIColor.black
		buttonWithImageOnScreen2.addTarget(self, action: #selector(TableViewController.buttonWithImageOnScreenPressed(buttonSender:)), for: .touchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen2)

		self.tableView.tableFooterView = tableViewFooter
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
	// MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete method implementation.
		// Return the number of rows in the section.
		var rows = 0

		if section == 0 {
			rows = 1
		} else if (section == 1) {
			rows = 3
		} else if (section == 2) {
			rows = 0
        }else if section == 3{
            rows = 1
        }

		return rows
	}
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var atitle = ""
        
        if (section == 0) {
            atitle = "Single photo"
        } else if (section == 1) {
            atitle = "Multiple photos"
        } else if (section == 2) {
            atitle = "Photos from library"
        } else if section == 3{
            atitle = "TapToClose"
        }
        
        return atitle

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellIdentifier)
        }
        
        // Configure
        if indexPath.section == 0 { cell?.textLabel?.text = "Local photo" }
        else if indexPath.section == 1 {
            if (indexPath.row == 0) { cell?.textLabel?.text = "Local photos" }
            else if (indexPath.row == 1) { cell?.textLabel?.text = "Photos from Flickr" }
            else if (indexPath.row == 2) { cell?.textLabel?.text = "Photos from Flickr - Custom" }
        } else if indexPath.section == 2 {
            cell?.textLabel?.text = "Photos from library"
        } else if indexPath.section == 3{
            cell?.textLabel?.text = "TapToClose"
        }
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
		// Create an array to store IDMPhoto objects
		var photos = [SSPhoto]()

		var photo: SSPhoto!

		if indexPath.section == 0 { // Local photo
			photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo2l", ofType: "jpg")!)
			photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
			photos.append(photo)
		} else if indexPath.section == 1 { // Multiple photos

			if indexPath.row == 0 { // Local Photos

				photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo1l", ofType: "jpg")!)
				photo.aCaption = "Grotto of the Madonna"
				photos.append(photo)

				photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo2l", ofType: "jpg")!)
				photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
				photos.append(photo)

				photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo3l", ofType: "jpg")!)
				photo.aCaption = "York Floods"
				photos.append(photo)

				photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo4l", ofType: "jpg")!)
				photo.aCaption = "Campervan"
				photos.append(photo)
			} else if (indexPath.row == 1 || indexPath.row == 2) { // Photos from Flickr or Flickr - Custom

				let photosWithURL = SSPhoto.photosWithURLs([
					URL(string: "http://ww4.sinaimg.cn/bmiddle/822f7258gw1f2ngfz5oibj21hc0u0wqf.jpg")!,
					URL(string: "http://ww2.sinaimg.cn/bmiddle/822f7258gw1f2ngfsc09ej21hc0u0dqd.jpg")!,
					URL(string: "http://ww1.sinaimg.cn/bmiddle/822f7258gw1f2nggaujw2j21hc0u0nc0.jpg")!,
					URL(string: "http://ww3.sinaimg.cn/bmiddle/822f7258gw1f2ngglkdc5j21hc0u0n90.jpg")!
				])
				photos += photosWithURL
			}
        }else if indexPath.section == 3{
            if indexPath.row == 0{
                photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo1l", ofType: "jpg")!)
                photo.aCaption = "Grotto of the Madonna"
                photos.append(photo)
            }
        }
        
		showBrowser(photos: photos, indexPath: indexPath as NSIndexPath)
	}

	private func showBrowser(photos: [SSPhoto], indexPath: NSIndexPath) {
		// Create and setup browser
		let browser = SSImageBrowser(aPhotos: photos, animatedFromView: nil)
		browser.delegate = self

		if (indexPath.section == 1) // Multiple photos
		{
			if (indexPath.row == 1) // Photos from Flickr
			{
				browser.displayCounterLabel = true
				browser.displayActionButton = false
			}
			else if (indexPath.row == 2) // Photos from Flickr - Custom
			{
				browser.actionButtonTitles = ["Option 1", "Option 2", "Option 3", "Option 4"]
				browser.displayCounterLabel = true
				browser.useWhiteBackgroundColor = true
			}
        }else if indexPath.section == 3{
            if indexPath.row == 0{
                let vc = SSImageBrowser.init(aPhotos: photos, useTapToClose: true, animatedFromView: nil)
                present(vc, animated: true, completion: nil)
            }
        }
		// Show
		present(browser, animated: true, completion: nil)
		tableView.deselectRow(at: indexPath as IndexPath, animated: true)
	}

	@objc private func buttonWithImageOnScreenPressed(buttonSender: UIButton) {

		// Create an array to store IDMPhoto objects
		var photos = [SSPhoto]()
		var photo: SSPhoto!

		if buttonSender.tag == 101 {
			photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo1l", ofType: "jpg")!)
			photo.aCaption = "Grotto of the Madonna"
			photos.append(photo)
		}

		photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo3l", ofType: "jpg")!)
		photo.aCaption = "York Floods"
		photos.append(photo)

		photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo2l", ofType: "jpg")!)
		photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
		photos.append(photo)

		photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo4l", ofType: "jpg")!)
		photo.aCaption = "Campervan"
		photos.append(photo)

		if buttonSender.tag == 102 {
			photo = SSPhoto(filePath: Bundle.main.path(forResource: "photo1l", ofType: "jpg")!)
			photo.aCaption = "Grotto of the Madonna"
			photos.append(photo)
		}

		// Create and setup browser
//		let browser = SSImageBrowser(aPhotos: photos, animatedFromView: buttonSender)
        let browser = SSImageBrowser(aPhotos: photos, useTapToClose: true, animatedFromView: buttonSender)
        // using initWithPhotos:animatedFromView: method to use the zoom-in animation
		browser.delegate = self
		browser.displayActionButton = true
		browser.displayArrowButton = true
		browser.displayCounterLabel = true
		browser.usePopAnimation = true
//        browser.displayDownloadButton = false
        browser.alwysShowDownloadButton = true
//        let att = NSAttributedString(string: "downL", attributes: [NSForegroundColorAttributeName: UIColor.red, NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
//        browser.downLoadButtonTitle = att
        browser.downLoadButtonFrame = CGRect(x: 200, y: 600, width: 50, height: 44)
		browser.scaleImage = buttonSender.currentImage
		if (buttonSender.tag == 102) {
			browser.useWhiteBackgroundColor = true
		}

		// Show
		present(browser, animated: true, completion: nil)
	}
}

extension TableViewController: SSImageBrowserDelegate {
    
	func photoBrowser(_ photoBrowser: SSImageBrowser, captionViewForPhotoAtIndex index: Int) -> SSCaptionView! {
		return nil
	}

	func photoBrowser(_ photoBrowser: SSImageBrowser, didDismissActionSheetWithButtonIndex index: Int, photoIndex: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, didDismissAtPageIndex index: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, didShowPhotoAtIndex index: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, willDismissAtPageIndex index: Int) {
	}
}
