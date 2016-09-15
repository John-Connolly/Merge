//
//  Merge.swift
//
//
//  Created by John Connolly on 2016-03-20.
//
//

import Foundation
import AVKit
import AVFoundation

final class Merge {
    
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
    
    static func overlayVideo(video: AVAsset, overlayImage: UIImage, completion: (URL: NSURL?) -> ()) {
        let mixComposition = AVMutableComposition()
        let videoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), ofTrack: video.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)
        } catch {
            print(error)
        }
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, video.duration)
        let videoLayerIntruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let videoAssetTrack: AVAssetTrack = video.tracksWithMediaType(AVMediaTypeVideo)[0]
        var isVideoAssetPortrait = false
        let videoTransform:CGAffineTransform = videoAssetTrack.preferredTransform
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            isVideoAssetPortrait = true
        }
        videoLayerIntruction.setTransform(videoAssetTrack.preferredTransform, atTime: kCMTimeZero)
        videoLayerIntruction.setOpacity(0.0, atTime: video.duration)
        mainInstruction.layerInstructions = [videoLayerIntruction]
        let mainCompositionInstruction = AVMutableVideoComposition()
        var naturalSize = CGSize()
        if isVideoAssetPortrait {
            naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width)
        } else {
            naturalSize = videoAssetTrack.naturalSize
        }
        var renderWidth, renderHeight: CGFloat
        renderWidth = naturalSize.width
        renderHeight = naturalSize.height
        mainCompositionInstruction.renderSize = CGSizeMake(renderWidth, renderHeight)
        mainCompositionInstruction.instructions = [mainInstruction]
        mainCompositionInstruction.frameDuration = CMTimeMake(1, 30)
        self.applyVideoEffectsToComposition(mainCompositionInstruction, size: naturalSize, overlayImage: overlayImage)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        let myPathDocs = documentsDirectory + "/export\(NSUUID().UUIDString).mov"
        let url = NSURL(fileURLWithPath: myPathDocs)
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = url
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainCompositionInstruction
        exporter?.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(),{
                completion(URL: exporter?.outputURL)
            })
        })
    }
    
    private static func applyVideoEffectsToComposition(composition: AVMutableVideoComposition, size: CGSize, overlayImage: UIImage) {
        let overlayLayer = CALayer()
        overlayLayer.contents = overlayImage.CGImage
        overlayLayer.frame = CGRectMake(0, 0, size.width, size.height)
        overlayLayer.masksToBounds = true
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, size.width, size.height)
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    }
}