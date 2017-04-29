![Merge](https://cloud.githubusercontent.com/assets/8390081/25558422/ae521b18-2cfc-11e7-8c4e-0bc714192599.png)

# Merge
[![Swift](http://img.shields.io/badge/swift-3.0-brightgreen.svg)](https://swift.org) 
---
##### What is it?
Overlay transparent PNG images on top of other images or videos. This is useful for apps that need to watermark videos, or  apps where a user can draw on top of a video.  

Used in https://itunes.apple.com/us/app/.gif/id1061699394?ls=1&mt=8 check it out!

## Getting Started
Merge is initialized with a configuration struct that is open for extension. Simply extend Merge to have full control over frame rate, export directory, export quality and overlay placement. 

```swift
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
```
#### Placement
- stretchFit:  Stretches the ovelay to cover the entire video frame. This is ideal for
situations for adding drawing to a video.

- custom: Custom coordinates for the ovelay and size for the overlay. 

```swift 
enum Placement {
case stretchFit
case custom(x: CGFloat, y: CGFloat, size: CGSize)
}
```


##### Overlay an image on a video.
- Note: For performance reasons the progress closure is not called on the main thread. 
```swift

let merge = Merge(config: .standard)

merge.overlayVideo(video: AVAsset, overlayImage: UIImage, completion: { url in

// Video done exporting
}) { progress in
// progress of video export
}

```


##### Installation
Just drag Merge.swift to the project tree
