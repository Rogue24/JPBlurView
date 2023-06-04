# JPBlurView & JPBlurAnimationView

## JPBlurView

`JPBlurView` is a `UIView` with a blur effect and customizable blur intensity. Internally, `JPBlurView` encapsulates `UIVisualEffectView` to achieve the frosted glass effect, and utilizes `UIViewPropertyAnimator` to implement custom blur intensity.

It is very easy to use, the code is as follows:
```swift
// 1.Creating a blurView.
let blurView = JPBlurView(effectStyle: .systemThinMaterialDark)

// 2.Adding blurView to a parent view.
parentView.addSubview(blurView)

// 3.Layout the blurView using frame or auto layout.
blurView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)

// 4.You can easily modify the blur intensity by modifying the intensity property!
blurView.intensity = 0.5
```
- `effectStyle` is of type UIBlurEffect.Style and needs to be customized by you. 
- The `intensity` has a default initial value of 1, but you can pass a custom value to it in the constructor method.
- The `intensity` property ranges from 0 to 1, representing 0% to 100% blur intensity.

The achieved effect looks like this:

![JPBlurView_1.gif](https://github.com/Rogue24/JPCover/raw/master/JPBlurView/JPBlurView_1.gif)

`JPBlurView` allows complete customization of the blur intensity and addresses the issue of becoming ineffective when entering the background mode. If you want to modify the blur intensity with animation effects, you can use `JPBlurAnimationView`.

## JPBlurAnimationView

`JPBlurAnimationView` inherits from `JPBlurView`, allows for animated modifications of the blur intensity. It internally relies on the pop library, enabling animated modifications of the blur intensity for a smoother transition effect.

Using JPBlurAnimationView is equally straightforward. Here's the code:
```swift
let blurView = JPBlurAnimationView(effectStyle: .systemThinMaterialDark)

// Adding to a parent view and applying layout...

blurView.setIntensity(from: 0,
                      to: 1,
                      duration: 0.5,
                      timingFunctionName: .easeInEaseOut)
```
The animation implementation utilizes a combination of `POPBasicAnimation` and `POPAnimatableProperty`. Here is the meaning of the parameters:
- The `from` parameter represents the starting blur intensity value. Default is `nil`, which represents starting the animation from the current blur intensity.
- The `to` parameter represents the target blur intensity value.
- The `duration` parameter represents the duration of the animation.
- The `timingFunctionName` parameter represents the name of the animation curve or timing function to be used during the animation. It defines the pace or rhythm of the animation over time, such as linear, ease-in, ease-out, ease-in-out, etc. Default is `nil`.

The animation effect will only be applied if the `duration` is greater than 0 and the `from` and `to` values are not equal. In this case, when the duration is positive and the starting and target blur intensities are different, the animation will be triggered, resulting in a smooth transition between the two blur intensity values.

The achieved effect looks like this:

![JPBlurAnimationView_1.gif](https://github.com/Rogue24/JPCover/raw/master/JPBlurView/JPBlurAnimationView_1.gif)

Additionally, you can make use of this convenient API:
```swift
blurView.setIntensity(0.5, animated: true)

/// The equivalent to the above API would be:
/// `blurView.setIntensity(from: nil, to: 0.5, duration: 0.3, timingFunctionName: nil)`

/// If the animated parameter is set to false, then it is equivalent to:
/// `blurView.intensity = 0.5`
```

During the animation process, you can use the `stopAnimation` method to stop the animation. At the point when the animation is stopped, the blur intensity will be set to the value it had when the animation was stopped.
```swift
blurView.stopAnimation()
```

By using `JPBlurAnimationView`, you can achieve interactive and animated transition effects, such as closing an image with a gesture:

![JPBlurAnimationView_2.gif](https://github.com/Rogue24/JPCover/raw/master/JPBlurView/JPBlurAnimationView_2.gif)

## Installation

JPBlurView & JPBlurAnimationView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
# This includes both JPBlurView and JPBlurAnimationView, which relies on the pop library.
pod 'JPBlurView'

# This includes only JPBlurView.
pod 'JPBlurView/Base'
```

## Author

Rogue24, zhoujianping24@hotmail.com

## License

JPBlurView is available under the MIT license. See the LICENSE file for more info.
