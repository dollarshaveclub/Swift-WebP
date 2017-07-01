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
//        presentImage("2_webp_ll", x: 15)
//        presentImage("2_webp_a", x: 150)
        presentImage("cell_animation", x: 150, y: 250)
        presentImage("gift-box-animated", x: 30, y: 400)
        
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.contentSize = CGSize(width: view.bounds.width, height: 5000)
    }
    
    
    func presentImage(_ str: String, x: CGFloat, y: CGFloat = 100) {
        // Do any additional setup after loading the view, typically from a nib.
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: str, withExtension: "webp")!)
            result = ImageDecoder(data: data, completion: { decoded in
                switch decoded {
                case .image(let image):
                    let imageView = UIImageView(image: image)
                    imageView.frame.origin = CGPoint(x: x, y: y)
                    self.scrollView.addSubview(imageView)
                case .animatedImage(let aniImage):
                    let animatedImageView = AnimatedImageView(image: aniImage, frame: .zero)
                    animatedImageView.frame = CGRect(x: x, y: y, width: 200, height: 200)
                    self.scrollView.addSubview(animatedImageView)
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

