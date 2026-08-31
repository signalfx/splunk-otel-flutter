/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/wireframe_capture_controller.dart';

/// Holds capture off while a route is moving.
///
/// A transition is the one moment when what is on screen is not a screen. Two
/// of them overlap, one of which has never been laid out where it is now, and
/// the frames in between belong to neither. Capturing them buys a few frames of
/// animation at the cost of reporting a state the application was never really
/// in.
///
/// It is also the moment when masking is least certain. Sensitivity is decided
/// by where a widget sits in the tree, and a transition is exactly when things
/// are drawn somewhere else: a `Hero` builds its flight in the navigator's
/// overlay, outside the subtree its `SensitiveArea` covers, so masked content
/// in flight is briefly not inside anything that masks it. Rather than reason
/// about which of those cases are safe, none of them are captured.
///
/// Install it on every navigator whose transitions should be excluded:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [CaptureNavigatorObserver(controller)],
/// );
///
/// // go_router
/// GoRouter(observers: [CaptureNavigatorObserver(controller)], routes: [...]);
/// ```
///
/// Scope and limitations, which follow from what a `NavigatorObserver` can see:
/// - It observes only the navigator it is attached to. Nested navigators, such
///   as per-tab stacks or shell routes, each need their own.
/// - Screen changes that push no route, such as switching an `IndexedStack` or
///   animating a widget in place, are not transitions to it.
class CaptureNavigatorObserver extends NavigatorObserver {
  /// Creates an observer holding [controller] off during transitions.
  ///
  /// The controller may be supplied later. An observer has to be built with
  /// the navigator, which is often earlier than whatever owns capture, and one
  /// with nothing attached simply does nothing.
  CaptureNavigatorObserver([this.controller]);

  /// Controller whose capture is suspended, if one is attached.
  WireframeCaptureController? controller;

  /// Suspension held for the duration of an interactive pop gesture.
  ///
  /// A drag has no animation to wait on while the finger is down, and may end
  /// in either direction, so it is held explicitly from start to finish.
  CaptureSuspension? _gesture;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    // A route arriving on an empty navigator is the screen the application
    // starts on. It is reported as a push and declares a transition duration,
    // but it has nothing to animate away from and does not use it, so waiting
    // that duration out would withhold the first half second of every session.
    _suspendUntilSettled(previousRoute == null ? null : route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // The route being popped is the one that animates out, so it, rather than
    // the one revealed underneath, says when the transition is over.
    _suspendUntilSettled(route, isReversing: true);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _suspendUntilSettled(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // A removed route leaves without animating, so only the frame in which the
    // stack changes is withheld.
    _suspendUntilSettled(null);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    super.didStartUserGesture(route, previousRoute);
    _gesture ??= controller?.suspend();
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();

    // A gesture that carried the route far enough is followed by a pop, which
    // takes its own suspension for the animation that finishes the job.
    _gesture?.release();
    _gesture = null;
  }

  /// Suspends capture until [route] has stopped moving.
  ///
  /// Waits out the transition the route declares before looking at how far
  /// along it is. A route cannot be asked that question while it is being
  /// pushed: `animation` is a proxy that stands in for the real one until the
  /// route is installed, and until then it answers that it has already
  /// finished. Once the declared duration has passed the proxy is attached, so
  /// what it says can be trusted, and a transition that is somehow still
  /// running keeps capture off until it is not.
  ///
  /// Routes without a transition, and routes whose transition is already over,
  /// still cost the frame in which the tree changes.
  void _suspendUntilSettled(Route<dynamic>? route, {bool isReversing = false}) {
    final suspension = controller?.suspend();
    if (suspension == null) {
      return;
    }

    final animation = route is TransitionRoute ? route.animation : null;
    final duration = switch (route) {
      final TransitionRoute<dynamic> transition when isReversing =>
        transition.reverseTransitionDuration,
      final TransitionRoute<dynamic> transition =>
        transition.transitionDuration,
      _ => Duration.zero,
    };

    if (duration == Duration.zero) {
      _releaseWhenSettled(suspension, animation);

      return;
    }

    Timer(duration, () => _releaseWhenSettled(suspension, animation));
  }

  /// Releases [suspension] at the end of the first frame [animation] is done.
  ///
  /// Released at the end of a frame rather than the moment the animation
  /// finishes, so that the tree capture resumes on has already been built.
  void _releaseWhenSettled(
    CaptureSuspension suspension,
    Animation<double>? animation,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (suspension.isReleased) {
        return;
      }

      if (_isSettled(animation)) {
        suspension.release();

        return;
      }

      _releaseWhenSettled(suspension, animation);
    });

    // A callback only runs if a frame happens, and the last frame of a
    // transition is often the last frame the application needs.
    WidgetsBinding.instance.scheduleFrame();
  }

  bool _isSettled(Animation<double>? animation) {
    if (animation == null) {
      return true;
    }

    try {
      return animation.isCompleted || animation.isDismissed;
    } catch (_) {
      // The route was disposed mid-transition, taking its animation with it.
      // There is nothing left to wait for.
      return true;
    }
  }
}
