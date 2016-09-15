![Merge](https://cloud.githubusercontent.com/assets/8390081/18536171/bc6c3c06-7ac8-11e6-8a4c-f013410d942b.png)

# Merge

Work in Progress
---
##### What is it?
Overlay transparent PNG images on top of other images or videos!  This is useful for apps that need to watermark images or videos, or Snapchat like apps where a user can draw on top of an image or video.  


##### Overlay Images.

```swift
 Merge.mergeImages(UIImage, topImage: UIImage, size: CGSize) { image in
            
        }
```
##### Overlay a video and an Image.

```swift
 Merge.overlayVideo(AVAsset, overlayImage: UIImage) { URL in
            // update some UI
        }
```


##### Installation
Just drag Merge.swift to the project tree
