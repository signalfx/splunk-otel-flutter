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

import 'package:flutter/services.dart';

const MethodChannel _nativeCrashChannel = MethodChannel(
  'com.splunk.rum.flutter.root.exampleapp/native_crash',
);

Future<void> simulateNativeCrash() {
  return _nativeCrashChannel.invokeMethod<void>('simulateCrash');
}

Future<void> installCrashUploadGrace(Duration gracePeriod) async {
  if (gracePeriod.inSeconds <= 0) {
    return;
  }

  try {
    await _nativeCrashChannel.invokeMethod<void>('installCrashUploadGrace', {
      'seconds': gracePeriod.inSeconds,
    });
  } on MissingPluginException {
    // Android-only crash upload test helper.
  }
}
