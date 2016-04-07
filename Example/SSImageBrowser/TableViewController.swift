//
//  TableViewController.swift
//  SSImageBrowser
//
//  Created by LawLincoln on 15/7/12.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import SSImageBrowser
class TableViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let tableViewFooter = UIView(frame: CGRectMake(0, 0, 320, 426 * 0.9 + 40))

		let buttonWithImageOnScreen1 = UIButton(type: .Custom)
		buttonWithImageOnScreen1.frame = CGRectMake(15, 0, 640 / 3 * 0.9, 426 / 2 * 0.9)
		buttonWithImageOnScreen1.tag = 101
		buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen1.setImage(UIImage(named: "photo1m.jpg"), forState: .Normal)

		buttonWithImageOnScreen1.imageView?.contentMode = .ScaleAspectFit
		buttonWithImageOnScreen1.backgroundColor = UIColor.blackColor()
		buttonWithImageOnScreen1.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(_:)), forControlEvents: .TouchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen1)

		let buttonWithImageOnScreen2 = UIButton(type: .Custom)
		buttonWithImageOnScreen2.frame = CGRectMake(15, 426 / 2 * 0.9 + 20, 640 / 2 * 0.9, 426 / 2 * 0.9)
		buttonWithImageOnScreen2.tag = 102
		buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen2.setImage(UIImage(named: "photo3m.jpg"), forState: .Normal)
		buttonWithImageOnScreen2.imageView?.contentMode = .ScaleAspectFit
		buttonWithImageOnScreen2.backgroundColor = UIColor.blackColor()
		buttonWithImageOnScreen2.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(_:)), forControlEvents: .TouchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen2)

		self.tableView.tableFooterView = tableViewFooter
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Potentially incomplete method implementation.
		// Return the number of sections.
		return 3
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete method implementation.
		// Return the number of rows in the section.
		var rows = 0

		if section == 0 {
			rows = 1
		} else if (section == 1) {
			rows = 3
		} else if (section == 2) {
			rows = 0
		}

		return rows
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		var atitle = ""

		if (section == 0) {
			atitle = "Single photo"
		} else if (section == 1) {
			atitle = "Multiple photos"
		} else if (section == 2) {
			atitle = "Photos on screen"
		}

		return atitle
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let CellIdentifier = "Cell"
		var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: CellIdentifier)
		}

		// Configure
		if indexPath.section == 0
		{
			cell?.textLabel?.text = "Local photo"
		}
		else if indexPath.section == 1
		{
			if (indexPath.row == 0) {
				cell?.textLabel?.text = "Local photos"
			} else if (indexPath.row == 1)
			{ cell?.textLabel?.text = "Photos from Flickr" }
			else if (indexPath.row == 2)
			{ cell?.textLabel?.text = "Photos from Flickr - Custom" }
		}

		return cell!
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		// Create an array to store IDMPhoto objects
		var photos = [SSPhoto]()

		var photo: SSPhoto!

		if indexPath.section == 0 { // Local photo
			photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo2l", ofType: "jpg")!)
			photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
			photos.append(photo)
		} else if indexPath.section == 1 { // Multiple photos

			if indexPath.row == 0 { // Local Photos

				photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo1l", ofType: "jpg")!)
				photo.aCaption = "Grotto of the Madonna"
				photos.append(photo)

				photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo2l", ofType: "jpg")!)
				photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
				photos.append(photo)

				photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo3l", ofType: "jpg")!)
				photo.aCaption = "York Floods"
				photos.append(photo)

				photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo4l", ofType: "jpg")!)
				photo.aCaption = "Campervan"
				photos.append(photo)
			} else if (indexPath.row == 1 || indexPath.row == 2) { // Photos from Flickr or Flickr - Custom

				let photosWithURL = SSPhoto.photosWithURLs([
					NSURL(string: "http://ww4.sinaimg.cn/bmiddle/822f7258gw1f2ngfz5oibj21hc0u0wqf.jpg")!,
					NSURL(string: "http://ww2.sinaimg.cn/bmiddle/822f7258gw1f2ngfsc09ej21hc0u0dqd.jpg")!,
					NSURL(string: "http://ww1.sinaimg.cn/bmiddle/822f7258gw1f2nggaujw2j21hc0u0nc0.jpg")!,
					NSURL(string: "http://ww3.sinaimg.cn/bmiddle/822f7258gw1f2ngglkdc5j21hc0u0n90.jpg")!
				])

				photos += photosWithURL
			}
		}

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
//                    browser.leftArrowImage          = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeft.png"];
//                    browser.rightArrowImage         = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRight.png"];
//                    browser.leftArrowSelectedImage  = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeftSelected.png"];
//                    browser.rightArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRightSelected.png"];
//                    browser.doneButtonImage         = [UIImage imageNamed:@"IDMPhotoBrowser_customDoneButton.png"];
//                    browser.view.tintColor          = [UIColor orangeColor];
//                    browser.progressTintColor       = [UIColor orangeColor];
//                    browser.trackTintColor          = [UIColor colorWithWhite:0.8 alpha:1];
			}
		}

		// Show
		self.presentViewController(browser, animated: true, completion: nil)
		self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	/*
	 // Override to support conditional editing of the table view.
	 override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	 // Return NO if you do not want the specified item to be editable.
	 return true
	 }
	 */

	/*
	 // Override to support editing the table view.
	 override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	 if editingStyle == .Delete {
	 // Delete the row from the data source
	 tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	 } else if editingStyle == .Insert {
	 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	 }
	 }
	 */

	/*
	 // Override to support rearranging the table view.
	 override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

	 }
	 */

	/*
	 // Override to support conditional rearranging of the table view.
	 override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	 // Return NO if you do not want the item to be re-orderable.
	 return true
	 }
	 */

	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using [segue destinationViewController].
	 // Pass the selected object to the new view controller.
	 }
	 */
	func buttonWithImageOnScreenPressed(buttonSender: UIButton) {

		// Create an array to store IDMPhoto objects
		var photos = [SSPhoto]()
		var photo: SSPhoto!

		if buttonSender.tag == 101 {
			photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo1l", ofType: "jpg")!)
			photo.aCaption = "Grotto of the Madonna"
			photos.append(photo)
		}

		photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo3l", ofType: "jpg")!)
		photo.aCaption = "York Floods"
		photos.append(photo)

		photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo2l", ofType: "jpg")!)
		photo.aCaption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
		photos.append(photo)

		photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo4l", ofType: "jpg")!)
		photo.aCaption = "Campervan"
		photos.append(photo)

		if buttonSender.tag == 102 {
			photo = SSPhoto(filePath: NSBundle.mainBundle().pathForResource("photo1l", ofType: "jpg")!)
			photo.aCaption = "Grotto of the Madonna"
			photos.append(photo)
		}

		// Create and setup browser
		let browser = SSImageBrowser(aPhotos: photos, animatedFromView: buttonSender) // using initWithPhotos:animatedFromView: method to use the zoom-in animation
		browser.delegate = self
		browser.displayActionButton = true
		browser.displayArrowButton = true
		browser.displayCounterLabel = true
		browser.usePopAnimation = true
		browser.scaleImage = buttonSender.currentImage
		if (buttonSender.tag == 102) {
			browser.useWhiteBackgroundColor = true
		}

		// Show
		self.presentViewController(browser, animated: true, completion: nil)
	}
}

extension TableViewController: SSImageBrowserDelegate {
	func photoBrowser(photoBrowser: SSImageBrowser, captionViewForPhotoAtIndex index: Int) -> SSCaptionView! {
		return nil
	}

	func photoBrowser(photoBrowser: SSImageBrowser, didDismissActionSheetWithButtonIndex index: Int, photoIndex: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, didDismissAtPageIndex index: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, didShowPhotoAtIndex index: Int) {
	}

	func photoBrowser(photoBrowser: SSImageBrowser, willDismissAtPageIndex index: Int) {
	}
}
