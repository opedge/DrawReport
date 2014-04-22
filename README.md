DrawReport
==========

[![endorse](https://api.coderwall.com/opedge/endorsecount.png)](https://coderwall.com/opedge)

Report UI issues by shaking your device to draw and annotate them.

This library is for app's testing/beta stage only. Check it before release your app.

Sometimes your meticulous user finds a bug in your iOS app's awesome and magnificent UI but does not know how to report it. Now it's easy to do with DrawReport - a small library for iOS app development process. Simply integrate it, shake your device and try to draw something!

## How To Get Started

### Installation with CocoaPods

I recommend you to take a look at [CocoaPods](http://cocoapods.org) and use it for dependency management in your iOS projects.

To add DrawReport to your project it is necessary that the following lines are in your Podfile:

```ruby
platform :ios, '7.0'
pod "DrawReport", "~> 0.1"
```

### Usage

You need to configure DrawReport in your AppDelegate class inside application:didFinishLaunchingWithOptions: method:

```objective-c
[DRPReporter startListeningShake];
```

You can stop listening for shake events when you don't want DrawReporter's functionality:

```objective-c
[DRPReporter stopListeningShake];
```

You can share with standard iOS available sharers (mail, messages, photo stream, copy, etc) in default configuration.

![Report Screenshot](https://raw.github.com/opedge/DrawReport/assets/Screenshot_01.png)

### Additional Sharers

#### Your own

If you want to implement your custom sharer you need to create object which implements DRPReporterViewControllerDelegate. You can share screenshot with drawings and notes implementing following method:

```objective-c
- (void)reporterViewController:(DRPReporterViewController *)reporterViewController didFinishDrawingImage:(UIImage *)image withNoteText:(NSString *)noteText;
```

If you want to share your code, I'm open for merge requests!

#### Basecamp

[Basecamp](https://basecamp.com) sharer which posts report as Todo to specified Todo list is already implemented and shipped out of the box. You need to specify Basecamp sharer dependency line in your Podfile instead of "DrawReport":

```ruby
pod "DrawReport/Basecamp", "~> 0.1"
```

##### Basecamp configuration

  1. Register your application (Basecamp auth scheme required it) on 37signals integrate site: [https://integrate.37signals.com](https://integrate.37signals.com). You will get "Client ID", "Client Secret" and "Redirect URI".

  2. Configure DRPBasecamp singleton instance in your AppDelegate before invoking "startListeningShake":
  
  ```objective-c
  [[DRPBasecamp sharedInstance] configureWithClientId:_<YOUR CLIENT ID>_
                                         clientSecret:_<YOUR CLIENT SECRET>_
                                          redirectURL:[NSURL URLWithString:_<YOUR REDIRECT URI>_]];
  [DRPReporter registerReporterViewControllerDelegate:[DRPBasecamp sharedInstance]];
  [DRPReporter startListeningShake];
  ```

![Basecamp Configuration Screenshot](https://raw.github.com/opedge/DrawReport/assets/Screenshot_Basecamp_01.png)

## Requirements

  - Supported build target - iOS 7.0 (Xcode 5.0, Apple LLVM compiler 5.0)
  - Earliest supported deployment target - iOS 6.0

## License

DrawReport is available under the MIT license. See the LICENSE file for more info.
