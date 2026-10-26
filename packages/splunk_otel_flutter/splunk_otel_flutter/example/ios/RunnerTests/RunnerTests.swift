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

import SplunkAgent
import UIKit
import XCTest

// If your plugin has been explicitly set to "type: .dynamic" in the Package.swift,
// you will need to add your plugin as a dependency of RunnerTests within Xcode.

@testable import splunk_otel_flutter
#if canImport(splunk_otel_flutter_app_start)
import splunk_otel_flutter_app_start
#endif

class AppStartCaptureTests: XCTestCase {

  private let launch = Date(timeIntervalSince1970: 1_000)
  private let firstForeground = Date(timeIntervalSince1970: 1_001)
  private let foreground = Date(timeIntervalSince1970: 1_002)
  private let active = Date(timeIntervalSince1970: 1_003)
  private let laterActive = Date(timeIntervalSince1970: 1_004)

  private var capture: AppStartCapture!

  override func setUp() {
    super.setUp()
    capture = AppStartCapture()
  }

  // MARK: - Launch origin

  func testInactiveAndActiveApplicationStatesMapToForeground() {
    XCTAssertEqual(AppStartCapture.launchOrigin(for: .inactive), .foreground)
    XCTAssertEqual(AppStartCapture.launchOrigin(for: .active), .foreground)
  }

  func testBackgroundApplicationStateMapsToBackground() {
    XCTAssertEqual(AppStartCapture.launchOrigin(for: .background), .background)
  }

  // MARK: - Lifecycle sequences

  func testForegroundLaunchCapturesLaunchAndActivation() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foreground)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertNil(snapshot?.willEnterForeground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testBackgroundLaunchCapturesForegroundBoundary() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .background)
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .background)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testDuplicateForegroundBoundariesReportUnknownLaunchOrigin() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .background)
    capture.recordWillEnterForeground(at: firstForeground)
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()?.toAppStartLifecycleSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .unknown)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testDuplicateForegroundBoundariesRemainUnknownBeforeActivation() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .background)
    capture.recordWillEnterForeground(at: firstForeground)
    capture.recordWillEnterForeground(at: foreground)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .unknown)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
    XCTAssertNil(snapshot?.didBecomeActive)
  }

  func testBackgroundTransitionDoesNotEraseConflictingForegroundEvidence() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordWillEnterForeground(at: firstForeground)
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidEnterBackground()
    capture.recordWillEnterForeground(at: active)
    capture.recordDidBecomeActive(at: laterActive)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .unknown)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertEqual(snapshot?.willEnterForeground, active)
    XCTAssertEqual(snapshot?.didBecomeActive, laterActive)
  }

  func testBackgroundLaunchStaysBackgroundAfterEnteringBackground() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .background)
    capture.recordDidEnterBackground()
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .background)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
  }

  func testInterruptedForegroundLaunchResumesWithPairedBoundary() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordWillEnterForeground(at: firstForeground)
    capture.recordDidEnterBackground()
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foregroundResumed)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testEnteringBackgroundDiscardsUnpairedBoundary() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidEnterBackground()

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foregroundResumed)
    XCTAssertNil(snapshot?.willEnterForeground)
    XCTAssertNil(snapshot?.didBecomeActive)
  }

  func testHandoffBeforeActivationLeavesActivationToNativeObserver() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foreground)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertNil(snapshot?.didBecomeActive)
  }

  func testMissedLaunchIsReportedAsUnknown() {
    capture.recordDidEnterBackground()
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .unknown)
    XCTAssertNil(snapshot?.didFinishLaunching)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testFirstLaunchTimestampIsKept() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordDidFinishLaunching(at: foreground, launchOrigin: .background)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foreground)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
  }

  func testLaunchAfterFirstActivationDoesNotChangeFrozenEvidence() {
    capture.recordDidBecomeActive(at: active)
    capture.recordDidFinishLaunching(at: laterActive, launchOrigin: .foreground)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .unknown)
    XCTAssertNil(snapshot?.didFinishLaunching)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testEvidenceIsFrozenAtFirstActivation() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordDidBecomeActive(at: active)
    capture.recordDidEnterBackground()
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: laterActive)

    let snapshot = capture.consumeSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .foreground)
    XCTAssertNil(snapshot?.willEnterForeground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  // MARK: - Handoff

  func testSnapshotIsConsumedOnlyOnce() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)

    XCTAssertNotNil(capture.consumeSnapshot())
    XCTAssertNil(capture.consumeSnapshot())
  }

  func testEvidenceAfterHandoffIsIgnored() {
    _ = capture.consumeSnapshot()
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .foreground)
    capture.recordDidBecomeActive(at: active)

    XCTAssertNil(capture.consumeSnapshot())
  }

  func testSnapshotConvertsToNativeLifecycleSnapshot() {
    capture.recordDidFinishLaunching(at: launch, launchOrigin: .background)
    capture.recordWillEnterForeground(at: foreground)
    capture.recordDidBecomeActive(at: active)

    let snapshot = capture.consumeSnapshot()?.toAppStartLifecycleSnapshot()

    XCTAssertEqual(snapshot?.launchOrigin, .background)
    XCTAssertEqual(snapshot?.didFinishLaunching, launch)
    XCTAssertEqual(snapshot?.willEnterForeground, foreground)
    XCTAssertEqual(snapshot?.didBecomeActive, active)
  }

  func testEveryLaunchOriginConvertsToNativeLaunchOrigin() {
    XCTAssertEqual(AppStartCaptureLaunchOrigin.foreground.toAppStartLaunchOrigin(), .foreground)
    XCTAssertEqual(AppStartCaptureLaunchOrigin.background.toAppStartLaunchOrigin(), .background)
    XCTAssertEqual(
      AppStartCaptureLaunchOrigin.foregroundResumed.toAppStartLaunchOrigin(),
      .foregroundResumed
    )
    XCTAssertEqual(AppStartCaptureLaunchOrigin.unknown.toAppStartLaunchOrigin(), .unknown)
  }
}
