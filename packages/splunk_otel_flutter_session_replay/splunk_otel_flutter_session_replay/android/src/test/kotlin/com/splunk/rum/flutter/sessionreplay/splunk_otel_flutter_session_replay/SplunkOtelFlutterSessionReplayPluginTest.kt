/*
 * Copyright 2025 Splunk Inc.
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

package com.splunk.rum.flutter.sessionreplay.splunk_otel_flutter_session_replay

import kotlin.test.Test
import kotlin.test.assertNotNull

/*
 * Unit tests for the SplunkOtelFlutterSessionReplayPlugin.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class SplunkOtelFlutterSessionReplayPluginTest {
    @Test
    fun pluginCanBeInstantiated() {
        val plugin = SplunkOtelFlutterSessionReplayPlugin()
        assertNotNull(plugin)
    }
}
