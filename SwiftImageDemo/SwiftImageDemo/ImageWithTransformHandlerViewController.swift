//
//  ImageWithTransformHandlerViewController.swift
//  SwiftImageDemo
//
//  Created by Jie Cao on 1/2/16.
//  Copyright © 2016 JieCao. All rights reserved.
//

import UIKit

class ImageWithTransformHandlerViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        let url = NSURL(string: "https://pbs.twimg.com/profile_images/567285191169687553/7kg_TF4l.jpeg")
        self.imageView.alpha = 0

        imageView.imageWithURL(url!, tranformsHandler: { (image) -> UIImage in
                SwiftImageUtils.roundImage(image, radius: 300.0)
            }) { (image, data, error, finished) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.imageView.image = image
                    UIView.animateWithDuration(2.0, animations: { () -> Void in
                        self.imageView.alpha = 1.0
                    })
                })
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
