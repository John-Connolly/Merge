![Merge](https://cloud.githubusercontent.com/assets/8390081/18536861/c9860614-7ace-11e6-8864-d223d0827fa8.png)

# Merge

Work in Progress
---
##### What is it?
Overlay transparent PNG images on top of other images or videos!  This is useful for apps that need to watermark images or videos, or Snapchat like apps where a user can draw on top of an image or video.  

Used in https://itunes.apple.com/us/app/.gif/id1061699394?ls=1&mt=8 check it out!

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
