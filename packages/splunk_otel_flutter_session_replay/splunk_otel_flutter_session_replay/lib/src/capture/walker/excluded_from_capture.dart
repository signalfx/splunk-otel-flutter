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

import 'package:flutter/widgets.dart';

/// Omits a subtree from wireframe capture entirely.
///
/// The subtree produces no nodes at all, as though it were not mounted. This
/// differs from masking, which still reports bounds so that layout survives:
/// exclusion is for interface that belongs to the tooling rather than to the
/// application, and that should leave no trace in a capture.
///
/// The debug overlay wraps itself in this so it does not appear in the
/// wireframes it is displaying, which would otherwise grow with every frame it
/// rendered of itself.
class ExcludedFromCapture extends StatelessWidget {
  /// Omits [child] and everything below it from capture.
  const ExcludedFromCapture({required this.child, super.key});

  /// Subtree to omit.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
