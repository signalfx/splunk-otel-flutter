/*
Copyright 2026 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Launch provenance of the initial activation.
///
/// Mirrors `AppStartLifecycleSnapshot.LaunchOrigin` of the native Splunk RUM agent.
typedef NS_ENUM(NSInteger, SplunkOtelFlutterLaunchOrigin) {
    SplunkOtelFlutterLaunchOriginUnknown = 0,
    SplunkOtelFlutterLaunchOriginForeground,
    SplunkOtelFlutterLaunchOriginBackground,
    SplunkOtelFlutterLaunchOriginForegroundResumed,
} NS_SWIFT_NAME(AppStartCaptureLaunchOrigin);

/// Lifecycle evidence captured before the native agent is installed.
NS_SWIFT_NAME(AppStartCaptureSnapshot)
@interface SplunkOtelFlutterAppStartSnapshot : NSObject

@property (nonatomic, readonly) SplunkOtelFlutterLaunchOrigin launchOrigin;
@property (nonatomic, readonly, nullable) NSDate *didFinishLaunching;
@property (nonatomic, readonly, nullable) NSDate *willEnterForeground;
@property (nonatomic, readonly, nullable) NSDate *didBecomeActive;

- (instancetype)init NS_UNAVAILABLE;

@end

/// Captures `UIApplication` lifecycle evidence from image load until the first activation.
///
/// The native agent is installed from Dart, which runs well after launch. The shared
/// instance is started from a load-time constructor, so the launch is observed even
/// when the plugin registers or the agent installs late. The native AppStart module
/// owns classification, validation, and suppression; this type only records evidence.
NS_SWIFT_NAME(AppStartCapture)
@interface SplunkOtelFlutterAppStartCapture : NSObject

@property (class, nonatomic, readonly) SplunkOtelFlutterAppStartCapture *sharedCapture NS_SWIFT_NAME(shared);

/// Maps the application state observed at `didFinishLaunching` to a launch origin.
+ (SplunkOtelFlutterLaunchOrigin)launchOriginForApplicationState:(UIApplicationState)applicationState;

/// Starts observing lifecycle notifications.
///
/// Does nothing after the first activation was recorded or the snapshot was consumed.
- (void)start;

/// Returns the captured evidence once and stops observing. Later calls return `nil`.
/// Conflicting foreground boundaries are reported with an unknown launch origin.
- (nullable SplunkOtelFlutterAppStartSnapshot *)consumeSnapshot;

- (void)recordDidFinishLaunchingAt:(NSDate *)timestamp launchOrigin:(SplunkOtelFlutterLaunchOrigin)launchOrigin;
- (void)recordWillEnterForegroundAt:(NSDate *)timestamp;
- (void)recordDidEnterBackground;
- (void)recordDidBecomeActiveAt:(NSDate *)timestamp;

@end

NS_ASSUME_NONNULL_END
