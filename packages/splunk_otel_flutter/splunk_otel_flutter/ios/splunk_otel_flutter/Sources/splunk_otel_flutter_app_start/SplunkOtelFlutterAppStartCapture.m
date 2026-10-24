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

#import "SplunkOtelFlutterAppStartCapture.h"

@interface SplunkOtelFlutterAppStartSnapshot ()

- (instancetype)initWithLaunchOrigin:(SplunkOtelFlutterLaunchOrigin)launchOrigin
                  didFinishLaunching:(nullable NSDate *)didFinishLaunching
                 willEnterForeground:(nullable NSDate *)willEnterForeground
                     didBecomeActive:(nullable NSDate *)didBecomeActive NS_DESIGNATED_INITIALIZER;

@end

@implementation SplunkOtelFlutterAppStartSnapshot

- (instancetype)initWithLaunchOrigin:(SplunkOtelFlutterLaunchOrigin)launchOrigin
                  didFinishLaunching:(nullable NSDate *)didFinishLaunching
                 willEnterForeground:(nullable NSDate *)willEnterForeground
                     didBecomeActive:(nullable NSDate *)didBecomeActive {
    self = [super init];
    if (self) {
        _launchOrigin = launchOrigin;
        _didFinishLaunching = didFinishLaunching;
        _willEnterForeground = willEnterForeground;
        _didBecomeActive = didBecomeActive;
    }

    return self;
}

@end

@implementation SplunkOtelFlutterAppStartCapture {
    SplunkOtelFlutterLaunchOrigin _launchOrigin;
    NSDate *_didFinishLaunching;
    NSDate *_willEnterForeground;
    NSDate *_didBecomeActive;
    BOOL _isObserving;
    BOOL _isConsumed;
}

+ (SplunkOtelFlutterAppStartCapture *)sharedCapture {
    static SplunkOtelFlutterAppStartCapture *sharedCapture;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCapture = [[SplunkOtelFlutterAppStartCapture alloc] init];
    });

    return sharedCapture;
}

+ (SplunkOtelFlutterLaunchOrigin)launchOriginForApplicationState:(UIApplicationState)applicationState {
    switch (applicationState) {
        case UIApplicationStateActive:
        case UIApplicationStateInactive:
            return SplunkOtelFlutterLaunchOriginForeground;

        case UIApplicationStateBackground:
            return SplunkOtelFlutterLaunchOriginBackground;
    }

    return SplunkOtelFlutterLaunchOriginUnknown;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Observation

- (void)start {
    @synchronized (self) {
        if (_isObserving || _isConsumed || _didBecomeActive != nil) {
            return;
        }

        _isObserving = YES;

        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self
                   selector:@selector(applicationDidFinishLaunching:)
                       name:UIApplicationDidFinishLaunchingNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationWillEnterForeground:)
                       name:UIApplicationWillEnterForegroundNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationDidEnterBackground:)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationDidBecomeActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
    }
}

- (void)stopObserving {
    if (!_isObserving) {
        return;
    }

    _isObserving = NO;
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSDate *timestamp = [NSDate date];
    SplunkOtelFlutterLaunchOrigin launchOrigin = SplunkOtelFlutterLaunchOriginUnknown;

    // `applicationState` may only be read on the main thread.
    if (NSThread.isMainThread && [notification.object isKindOfClass:UIApplication.class]) {
        UIApplication *application = notification.object;
        launchOrigin = [SplunkOtelFlutterAppStartCapture launchOriginForApplicationState:application.applicationState];
    }

    [self recordDidFinishLaunchingAt:timestamp launchOrigin:launchOrigin];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self recordWillEnterForegroundAt:[NSDate date]];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self recordDidEnterBackground];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self recordDidBecomeActiveAt:[NSDate date]];
}

#pragma mark - Evidence

- (void)recordDidFinishLaunchingAt:(NSDate *)timestamp launchOrigin:(SplunkOtelFlutterLaunchOrigin)launchOrigin {
    @synchronized (self) {
        if (_isConsumed || _didBecomeActive != nil || _didFinishLaunching != nil) {
            return;
        }

        _didFinishLaunching = timestamp;
        _launchOrigin = launchOrigin;
    }
}

- (void)recordWillEnterForegroundAt:(NSDate *)timestamp {
    @synchronized (self) {
        if (_isConsumed || _didBecomeActive != nil) {
            return;
        }

        _willEnterForeground = timestamp;
    }
}

- (void)recordDidEnterBackground {
    @synchronized (self) {
        if (_isConsumed || _didBecomeActive != nil) {
            return;
        }

        if (_launchOrigin == SplunkOtelFlutterLaunchOriginForeground) {
            _launchOrigin = SplunkOtelFlutterLaunchOriginForegroundResumed;
        }

        // The foreground boundary must pair with the activation that follows.
        _willEnterForeground = nil;
    }
}

- (void)recordDidBecomeActiveAt:(NSDate *)timestamp {
    @synchronized (self) {
        if (_isConsumed || _didBecomeActive != nil) {
            return;
        }

        _didBecomeActive = timestamp;
        [self stopObserving];
    }
}

- (nullable SplunkOtelFlutterAppStartSnapshot *)consumeSnapshot {
    @synchronized (self) {
        if (_isConsumed) {
            return nil;
        }

        _isConsumed = YES;
        [self stopObserving];

        return [[SplunkOtelFlutterAppStartSnapshot alloc] initWithLaunchOrigin:_launchOrigin
                                                            didFinishLaunching:_didFinishLaunching
                                                           willEnterForeground:_willEnterForeground
                                                               didBecomeActive:_didBecomeActive];
    }
}

@end

// Runs at image load, before `UIApplicationMain` posts `didFinishLaunching`.
__attribute__((constructor))
static void SplunkOtelFlutterStartAppStartCapture(void) {
    [SplunkOtelFlutterAppStartCapture.sharedCapture start];
}
