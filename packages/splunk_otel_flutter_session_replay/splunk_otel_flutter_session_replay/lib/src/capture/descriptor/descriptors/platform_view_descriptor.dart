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

import 'package:flutter/rendering.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';

/// Identifier of the embedded native view [renderObject] hosts, if any.
///
/// A platform view is a hole in the Flutter picture through which a native view
/// shows. Its identifier is what lets the native recorder find that view and
/// capture it with the rest of the native hierarchy, so it is the one piece of
/// a platform view worth reporting.
///
/// Both shapes a platform view takes are covered: the render box used for
/// Android and for surface-composited views, which names its controller
/// `controller`, and the Darwin one used for iOS and macOS, which names it
/// `viewController`.
int? nativeViewIdOf(RenderObject renderObject) {
  if (renderObject is PlatformViewRenderBox) {
    return renderObject.controller.viewId;
  }
  if (renderObject is RenderDarwinPlatformView) {
    return renderObject.viewController.id;
  }

  return null;
}

/// Describes a platform view as an empty region.
///
/// Registered so a platform view is never asked to paint on the capture path.
/// Its content belongs to the native view behind it, which the native recorder
/// captures through the reported identifier; there is nothing Flutter could
/// describe here, and its real paint only manages the compositing hole.
class PlatformViewDescriptor extends ElementDescriptor {
  /// Creates the descriptor.
  const PlatformViewDescriptor();
}
