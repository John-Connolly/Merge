//
//  Merge.swift
//  
//
//  Created by John Connolly on 2016-03-20.
//
//

//
//  Merge.swift
//  Overlay
//
//  Created by John Connolly on 2016-03-20.
//  Copyright © 2016 John Connolly. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation


class Merge {
    
    private static let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    
    static func mergeImages(bottomImage: UIImage, topImage: UIImage, size: CGSize, complete: (image: UIImage) -> ()) {
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            bottomImage.drawInRect(CGRect(origin: .zero, size: size))
            topImage.drawInRect(CGRect(origin: .zero, size: size))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            complete(image: newImage)
        }
    }
    
    
    static func mergeVideoAndImage(asset: AVURLAsset, overlay: CALayer, complete: (url: NSURL) -> ()) {
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID:0)
        let timeRange:CMTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        let videoTrack:AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        
        do {
            try compositionVideoTrack.insertTimeRange(timeRange, ofTrack: videoTrack, atTime: kCMTimeZero)
        } catch {
            print(error)
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        let videoSize:CGSize = getVideoSize(videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        let parentLayer:CALayer = CALayer()
        let videoLayer:CALayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        overlay.frame = videoLayer.frame
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlay)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        videoComposition.renderSize = CGSizeMake(videoSize.width, videoSize.height)
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let session:AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)!
        session.videoComposition = videoComposition
        session.outputURL = NSURL.fileURLWithPath(getFilePath() as String)
        session.outputFileType = AVFileTypeMPEG4
        session.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                if session.status == AVAssetExportSessionStatus.Completed {
                    complete(url: session.outputURL!)
                } else {
                    print("fail:(")
                }
            })
        })
    }
    
    private static func getVideoSize(videoTrack:AVAssetTrack) -> CGSize {
        var videoSize = videoTrack.naturalSize
        let transform:CGAffineTransform = videoTrack.preferredTransform
        if transform.a == 0 && transform.d == 0 && transform.b == 1.0 || transform.b == -1.0 && transform.c == 1.0 || transform.c == -1.0 {
            videoSize = CGSizeMake(videoSize.height, videoSize.width)
        }
        return videoSize
    }
    
    private static func getFilePath() -> NSString {
        let date = NSDate().timeIntervalSince1970
        let filePath:NSString = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("file\(date).mp4")
        return filePath
    }
}




