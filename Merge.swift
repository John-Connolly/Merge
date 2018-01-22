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

    fileprivate let configuration: MergeConfiguration

    init(config: MergeConfiguration) {
        self.configuration = config
    }

    fileprivate var fileUrl: URL {
        let fullPath = configuration.directory + "/export\(NSUUID().uuidString).mov"
        return URL(fileURLWithPath: fullPath)
    }

    /**
     Overlays and exports a video with a desired UIImage on top.

     - Parameter video: AVAsset
     - Paremeter overlayImage: UIImage
     - Paremeter completion: Completion Handler
     - Parameter progressHandler: Returns the progress every 500 milliseconds.
     */
    func overlayVideo(video: AVAsset,
                      overlayImage: UIImage,
                      completion: @escaping (_ URL: URL?) -> Void,
                      progressHandler: @escaping (_ progress: Float) -> Void) {
        let videoTracks = video.tracks(withMediaType: AVMediaTypeVideo)
        guard !videoTracks.isEmpty else { return }
        let videoTrack = videoTracks[0]

        let audioTracks = video.tracks(withMediaType: AVMediaTypeAudio)
        let audioTrack = audioTracks.isEmpty ? nil : audioTracks[0]
        let compositionTry = try? Composition(duration: video.duration, videoAsset: videoTrack, audioAsset: audioTrack)

        guard let composition = compositionTry else { return }

        let videoTransform = Transform(videoTrack.preferredTransform)
        let layerInstruction = LayerInstruction(track: composition.videoTrack, transform: videoTrack.preferredTransform, duration: video.duration)
        let instruction = Instruction(length: video.duration, layerInstructions: [layerInstruction.instruction])
        let size = Size(isPortrait: videoTransform.isPortrait, size: videoTrack.naturalSize)
        let layer = Layer(overlay: overlayImage, size: size.naturalSize, placement: configuration.placement)
        let videoComposition = VideoComposition(size: size.naturalSize, instruction: instruction,
                                                frameRate: configuration.frameRate,
                                                layer: layer
        )
        Exporter(asset: composition.asset, outputUrl: fileUrl, composition: videoComposition.composition, quality: configuration.quality).map { exporter in
            exporter.render { url in
                completion(url)
            }
            exporter.progress = { progress in
                progressHandler(progress)
            }
            } ?? completion(nil)
    }
}

/**
 Determines overlay placement.

 - stretchFit:  Stretches the ovelay to cover the entire video frame. This is ideal for
 situations for adding drawing to a video.
 - custom: Custom coordinates for the ovelay.

 */

enum Placement {

    case stretchFit
    case custom(x: CGFloat, y: CGFloat, size: CGSize)

    func rect(videoSize: CGSize) -> CGRect {
        switch self {
        case .stretchFit: return CGRect(origin: .zero, size: videoSize)
        case .custom(let x, let y, let size): return CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }
}

/**
 Determines export Quality

 - low
 - medium
 - high
 */

enum Quality: String {

    case low
    case medium
    case high

    var value: String {
        switch self {
        case .low: return AVAssetExportPresetLowQuality
        case .medium: return AVAssetExportPresetMediumQuality
        case .high: return AVAssetExportPresetHighestQuality
        }
    }
}

fileprivate final class LayerInstruction {

    let instruction: AVMutableVideoCompositionLayerInstruction

    init(track: AVMutableCompositionTrack, transform: CGAffineTransform, duration: CMTime) {
        instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        instruction.setTransform(transform, at: kCMTimeZero)
        instruction.setOpacity(0.0, at: duration)
    }

}

fileprivate final class Composition {

    let asset = AVMutableComposition()
    let videoTrack: AVMutableCompositionTrack
    var audioTrack: AVMutableCompositionTrack?

    init(duration: CMTime, videoAsset: AVAssetTrack, audioAsset: AVAssetTrack? = nil) throws {
        videoTrack = asset.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                           preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration),
                                       of: videoAsset,
                                       at: kCMTimeZero)

        if let audioAsset = audioAsset {
            audioTrack = asset.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                               preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration),
                                            of: audioAsset,
                                            at: kCMTimeZero)
        }
    }

}

fileprivate final class Instruction {

    let videoComposition = AVMutableVideoCompositionInstruction()

    init(length: CMTime, layerInstructions: [AVVideoCompositionLayerInstruction]) {
        videoComposition.timeRange = CMTimeRangeMake(kCMTimeZero, length)
        videoComposition.layerInstructions = layerInstructions
    }
}

fileprivate final class VideoComposition {

    let composition = AVMutableVideoComposition()

    init(size: CGSize, instruction: Instruction, frameRate: Int32, layer: Layer) {
        composition.renderSize = size
        composition.instructions = [instruction.videoComposition]
        composition.frameDuration = CMTimeMake(1, frameRate)
        composition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: layer.videoAndParent.video,
            in: layer.videoAndParent.parent
        )
    }
}

fileprivate final class Layer {

    fileprivate let overlay: UIImage
    fileprivate let size: CGSize
    fileprivate let placement: Placement

    init(overlay: UIImage, size: CGSize, placement: Placement) {
        self.overlay = overlay
        self.size = size
        self.placement = placement
    }

    fileprivate var frame: CGRect {
        return CGRect(origin: .zero, size: size)
    }

    fileprivate var overlayFrame: CGRect {
        return placement.rect(videoSize: size)
    }

    lazy var videoAndParent: VideoAndParent = {
        let overlayLayer = CALayer()
        overlayLayer.contents = self.overlay.cgImage
        overlayLayer.frame = self.overlayFrame
        overlayLayer.masksToBounds = true

        let videoLayer = CALayer()
        videoLayer.frame = self.frame

        let parentLayer = CALayer()
        parentLayer.frame = self.frame
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        return VideoAndParent(video: videoLayer, parent: parentLayer)
    }()

    final class VideoAndParent {
        let video: CALayer
        let parent: CALayer

        init(video: CALayer, parent: CALayer) {
            self.video = video
            self.parent = parent
        }
    }
}

///  A wrapper of AVAssetExportSession.
fileprivate final class Exporter {

    fileprivate let session: AVAssetExportSession

    var progress: ((_ progress: Float) -> Void)?

    init?(asset: AVMutableComposition, outputUrl: URL, composition: AVVideoComposition, quality: Quality) {
        guard let session = AVAssetExportSession(asset: asset, presetName: quality.value) else { return nil }
        self.session = session
        self.session.outputURL = outputUrl
        self.session.outputFileType = AVFileTypeQuickTimeMovie
        self.session.videoComposition = composition
    }

    func render(complete: @escaping (_ url: URL?) -> Void) {
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async(group: group) {
            self.session.exportAsynchronously {
                group.leave()
                DispatchQueue.main.async {
                    complete(self.session.outputURL)
                }
            }
            self.progress(session: self.session, group: group)
        }
    }

    /**
     Polls the AVAssetExportSession status every 500 milliseconds.

     - Parameter session: AVAssetExportSession
     - Parameter group: DispatchGroup
     */
    private func progress(session: AVAssetExportSession, group: DispatchGroup) {
        while session.status == .waiting || session.status == .exporting {
            progress?(session.progress)
            _ = group.wait(timeout: DispatchTime.now() + .milliseconds(500))
        }

    }

}
/// Provides an easy way to detemine if the video was taken in landscape or portrait.
private struct Transform {

    fileprivate let transform: CGAffineTransform

    init(_ transform: CGAffineTransform) {
        self.transform = transform
    }

    var isPortrait: Bool {
        guard transform.a == 0 && transform.d == 0 else { return false }
        switch (transform.b, transform.c) {
        case(1.0, -1.0): return true
        case(-1.0, 1.0): return true
        default: return false
        }
    }
}

private struct Size {
    fileprivate let isPortrait: Bool
    fileprivate let size: CGSize

    var naturalSize: CGSize {
        return isPortrait ? CGSize(width: size.height, height: size.width) : size
    }
}

/// Configuration struct.  Open for extension.
struct MergeConfiguration {
    let frameRate: Int32
    let directory: String
    let quality: Quality
    let placement: Placement

}

extension MergeConfiguration {

    static var standard: MergeConfiguration {
        return MergeConfiguration(frameRate: 30, directory: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], quality: Quality.high, placement: Placement.stretchFit)
    }
}

