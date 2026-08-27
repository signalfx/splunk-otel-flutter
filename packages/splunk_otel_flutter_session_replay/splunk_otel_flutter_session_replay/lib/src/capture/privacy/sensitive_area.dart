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

/// Marks a subtree as containing, or explicitly not containing, private
/// content.
///
/// Wrapping a subtree suppresses everything it would have painted in the
/// captured wireframe. The nodes and their bounds are still reported, so layout
/// is preserved, but no colour, text, or image content from inside the subtree
/// reaches the capture.
///
/// ```dart
/// SensitiveArea(child: AccountBalance())
/// ```
///
/// Setting [isSensitive] to false reveals a subtree that an enclosing
/// [SensitiveArea] would otherwise have masked, which is how a non-private
/// region inside a broadly masked screen is exempted:
///
/// ```dart
/// SensitiveArea(
///   child: Column(
///     children: <Widget>[
///       AccountBalance(),
///       SensitiveArea(isSensitive: false, child: HelpFooter()),
///     ],
///   ),
/// )
/// ```
///
/// This widget paints nothing and creates no render object, so it costs one
/// element in the tree and nothing at paint time.
class SensitiveArea extends StatelessWidget {
  /// Marks [child] according to [isSensitive].
  const SensitiveArea({
    required this.child,
    this.isSensitive = true,
    super.key,
  });

  /// Subtree the marking applies to.
  final Widget child;

  /// Whether the subtree should be masked.
  ///
  /// Defaults to true. When false, the subtree is revealed even if an ancestor
  /// marked it sensitive.
  final bool isSensitive;

  @override
  Widget build(BuildContext context) => child;
}
