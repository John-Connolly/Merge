![Merge](https://cloud.githubusercontent.com/assets/8390081/13906983/01b1bd04-eeba-11e5-8d36-65648a87c88a.png)

# Merge
---
##### What is it?
Overlay transparent PNG images on top of other images or videos!  This is useful for apps that need to watermark images or videos, or Snapchat like apps where a user can draw on top of an image or video.  


##### Overlay Images.

```swift
 Overlay.merge(bottomImage: UIImage, topImage: UIImage, size: CGSize) { (image) -> () in
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
            }
        }
```
##### Overlay a video and an Image.

```swift
 Overlay.mergeVideoAndImage(AVURLAsset, overlay: CALayer) { (url) -> () in
            // update some UI
        }
```
