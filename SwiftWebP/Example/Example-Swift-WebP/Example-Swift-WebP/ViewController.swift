//
//  ViewController.swift
//  Example-Swift-WebP
//
//  Created by Michael Mork on 6/22/17.
//  Copyright © 2017 Michael Mork. All rights reserved.
//

import UIKit
import SwiftWebP

class ViewController: UIViewController {
    var result: ImageDecoder?
    var scrollView = UIScrollView()
    override func viewDidLoad() {
        super.viewDidLoad()
        presentImage("wsp@2x", x: 15)
//        presentImage("gift-box-animated", x: 15)
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.contentSize = CGSize(width: view.bounds.width, height: 5000)
    }
    
    
    func presentImage(_ str: String, x: CGFloat) {
        // Do any additional setup after loading the view, typically from a nib.
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: str, withExtension: "webp")!)
            result = ImageDecoder(data: data, completion: { decoded in
                var y: CGFloat = 64.0
                switch decoded {
                case .image(let image):
                    let imageView = UIImageView(image: image)
                    self.scrollView.addSubview(imageView)
                case .animatedImage(let aniImage):
                    for image in aniImage.frames! {
                        let imageView = UIImageView(image: image.image)
                        imageView.frame.origin = CGPoint(x: x, y: y)
                        self.scrollView.addSubview(imageView)
                        y += imageView.bounds.height + 10
                    }
                default :
                    print("you dun fukkedup")
                }
            })
            
        } catch {
            print("error")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

