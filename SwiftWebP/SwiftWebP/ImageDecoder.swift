//
//  ImageDecoder.swift
//  SwiftWebP̨
//
//  Created by Michael Mork on 1/29/17.
//  Copyright © 2017 Dollar Shave Club. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import ImageIO
import MobileCoreServices
import WebP
import WebPDemux

public enum ImageDecodeResult {
    case image(UIImage)
    case animatedImage(AnimatedImage)
    case error(ImageDecodeError)
}

public enum ImageDecodeError: Error {
    case unknown
    case malformedData
    case gif
    case image
}

typealias ImageDecodeProgress = (_ progress: Float)->()

public class ImageDecoder {
    
    var decodeProgress: ImageDecodeProgress?

    public init() {}

    static func decode(data: Data, completion: @escaping (ImageDecodeResult)->()) {
        let decoder = ImageDecoder()
        DispatchQueue.global().async {
            let image = decoder.decode(data: data as Data)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func decode(data: Data) -> ImageDecodeResult {
        var imageDecode = ImageDecodeResult.error(.unknown)
        let scale = UIScreen.main.scale
        data.withUnsafeBytes { (bytesPointer: UnsafePointer<UInt8>) -> Void in
            if WebPGetInfo(bytesPointer, data.count, nil, nil) != 0 {
                imageDecode = decodeWebPData(data, scale: scale)
            } else {
                guard let goodRef = CGImageSourceCreateWithData(data as CFData, nil) as CGImageSource?,
                    let imageSourceContainerType = CGImageSourceGetType(goodRef) as CFString? else {
                        return // test this failure
                }
                if UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) {
                    imageDecode = decodeGif(goodRef, data: data, scale: scale)
                } else if UTTypeConformsTo(imageSourceContainerType, kUTTypeImage) {
                    if let image = UIImage(data: data, scale: scale) as UIImage? {
                        updateProgress(1.0)
                        imageDecode = .image(image)
                    }
                }
            }
        }
        return imageDecode
    }
    
    func updateProgress(_ progress: Float) {
        guard let decodeProgress = decodeProgress else {return}
        var progress = progress
        if progress > 1.0 {
            progress = 1.0
        } else if progress < 0.0 {
            progress = 0.0
        }
        
        DispatchQueue.main.async {
            decodeProgress(progress)
        }
    }
    
    func decodeWebPData(_ data: Data, scale: CGFloat) -> ImageDecodeResult {
        var imageFrames = [ImageFrame]()
        var webPImageInfo: (size: CGSize, backgroundColor: UIColor) = (.zero, .clear)
        
        data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Void in
            var webPData = WebPData(bytes: pointer, size: data.count)
            // setup the demux we need for animated webp images.
            let demux = WebPDemux(&webPData)
            
            let frameCount = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT)
            let backgroundColor = WebPDemuxGetI(demux, WEBP_FF_BACKGROUND_COLOR)
            
            let canvasWidth = CGFloat(WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH))/scale
            let canvasHeight = CGFloat(WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT))/scale
            let b = (backgroundColor >> 24) & 0xff
            let g = (backgroundColor >> 16) & 0xff
            let r = (backgroundColor >> 8) & 0xff
            let a = backgroundColor & 0xff
            webPImageInfo = (CGSize(width: canvasWidth, height: canvasHeight), UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)))
            var config = WebPDecoderConfig()
            WebPInitDecoderConfig(&config)
            config.options.use_threads = 1
            let progressOffset: CGFloat = 1/CGFloat(frameCount)
            var progress: CGFloat = 0.0
            var iterator = WebPIterator()
            WebPDemuxGetFrame(demux, 1, &iterator)
            if iterator.num_frames > 1 {
                repeat {
                    let webPData = iterator.fragment
                    if let image = createImage(bytes: webPData.bytes, size: webPData.size, config: &config, scale: scale) {
                        imageFrames.append(ImageFrame(frame: CGRect(origin: .zero, size: image.size), image: image, dispose: true, blend: false, duration: 0))
                        var duration = iterator.duration
                        if duration <= 0 {
                            duration = 100
                        }
                        
                        let blend = iterator.blend_method == WEBP_MUX_BLEND
                        let dispose = iterator.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND
                        let frame = CGRect(x: CGFloat(iterator.x_offset)/scale, y: CGFloat(iterator.y_offset)/scale, width: CGFloat(iterator.width)/scale, height: CGFloat(iterator.height)/scale)
                        
                        imageFrames.append(ImageFrame(frame: frame, image: image, dispose: dispose, blend: blend, duration: Int(duration)))
                        progress += progressOffset
                        updateProgress(Float(progress))
                    }
                } while (WebPDemuxNextFrame(&iterator) == 1)
                
            } else {
                
                data.withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Void in
                    if let image = createImage(bytes: pointer, size: webPData.size, config: &config, scale: scale) {
                        imageFrames.append(ImageFrame(frame: CGRect(origin: .zero, size: image.size), image: image, dispose: true, blend: false, duration: 0))
                        progress += progressOffset
                        updateProgress(Float(progress))
                    }
                })
            }
        }
        
        if imageFrames.count > 1 {
            let image = AnimatedImage(frame: .zero)
            image.frames = imageFrames
            image.size = webPImageInfo.size
            image.backgroundColor = webPImageInfo.backgroundColor
            return .animatedImage(image)
        } else if imageFrames.count == 1 {
            return .image(imageFrames.first!.image)
        } else {
            return .error(.unknown)
        }
    }
    
    func decodeGif(_ ref:CGImageSource, data: Data, scale: CGFloat) -> ImageDecodeResult {
        var largestWidth: Int = 0
        var largestHeight: Int = 0
        let frameCount = CGImageSourceGetCount(ref)
        let progressOffset = 1/frameCount
        var progress = 0
        var frames = [ImageFrame]()
        let animatedImage = AnimatedImage(frame: .zero)
        for i in 0..<frameCount {
            if let imageRef = CGImageSourceCreateImageAtIndex(ref, i, nil) {
                let image = UIImage(cgImage: imageRef)
                if let framePropsD = CGImageSourceCopyPropertiesAtIndex(ref, i, nil) as NSDictionary?
                {
                    let frameProps = framePropsD
                    guard let height = frameProps.object(forKey: kCGImagePropertyPixelHeight) as? NSNumber,
                        let width = frameProps.object(forKey: kCGImagePropertyPixelWidth) as? NSNumber else {return .error(.gif) }
                    
                    let frame = CGRect(origin: .zero, size: CGSize(width: CGFloat(truncating: width)/scale, height: CGFloat(truncating: height)/scale))
                    if Int(frame.size.height) > largestHeight {
                        largestHeight = Int(frame.size.height)
                        largestWidth = Int(frame.size.width)
                    }
                    
                    let gifProps = frameProps.object(forKey: kCGImagePropertyGIFDictionary) as! NSDictionary
                    var duration: CGFloat = 0.1
                    let bottom = gifProps.object(forKey: kCGImagePropertyGIFDelayTime)
                    let top = gifProps.object(forKey: kCGImagePropertyGIFUnclampedDelayTime)
                    if let delayTime = top ?? bottom {
                        duration = CGFloat((delayTime as AnyObject).floatValue ?? 0.1)
                    }
                    
                    duration = duration * 1000.0 // convert centisecond -> millisecond
                    
                    let newFrame = ImageFrame(frame: frame, image: image, dispose: true, blend: false, duration: Int(duration))
                    frames.append(newFrame)
                    progress += progressOffset
                    updateProgress(Float(progress))
                }
            }
            animatedImage.frames = frames
            animatedImage.size = CGSize(width: largestWidth, height: largestHeight)
        }
        return ImageDecodeResult.animatedImage(animatedImage)
    }

    func createImage(bytes: UnsafePointer<UInt8>, size: size_t, config: UnsafeMutablePointer<WebPDecoderConfig>, scale: CGFloat) -> UIImage? {
        if VP8StatusCode(WebPDecode(bytes, size, config).rawValue) != VP8_STATUS_OK {
            return nil
        }
        var height: Int32 = 0
        var width: Int32 = 0
        if let data = WebPDecodeRGBA(bytes, size, &width, &height) {
            var config = config
            let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
                // https://developer.apple.com/reference/coregraphics/cgdataproviderreleasedatacallback
                // N.B. 'CGDataProviderRelease' is unavailable: Core Foundation objects are automatically memory managed
                return
            }
            let provider = CGDataProvider(dataInfo: &config, data: UnsafeRawPointer(data), size: Int(width*height*4), releaseData:releaseMaskImagePixelData)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo: CGBitmapInfo = [CGBitmapInfo(rawValue: (0 << 12)), CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)]
            guard let imageRef = CGImage.init(width: Int(width), height: Int(height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4*Int(width), space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
                return nil
            }
            let image = UIImage(cgImage: imageRef, scale: scale, orientation: .up)
            WebPFreeDecBuffer(&config.pointee.output);
            return image
        } else {
            return nil
        }
    }
}
