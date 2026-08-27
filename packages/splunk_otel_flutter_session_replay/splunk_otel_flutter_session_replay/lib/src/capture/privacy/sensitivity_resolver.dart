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
import 'package:flutter/widgets.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/privacy/sensitive_area.dart';

/// What an element says about whether its subtree is private.
enum Sensitivity {
  /// Mask this element and everything below it.
  sensitive,

  /// Reveal this element and everything below it, overriding an enclosing
  /// [sensitive] marking.
  notSensitive,

  /// Express no opinion and take the enclosing decision.
  inherit,
}

/// Decides which parts of the tree must not be captured.
///
/// Masking is deliberately decided per element rather than by rectangle. A
/// rectangle captured on one frame does not necessarily cover the same content
/// on the next, so anything that scrolls or animates would leak during the
/// frames where the two disagree.
///
/// Subclass and override [resolve] to add application-specific rules.
class SensitivityResolver {
  /// Creates a resolver.
  const SensitivityResolver({this.maskTextInput = true});

  /// Whether editable text is masked without being marked.
  ///
  /// Defaults to true. Text the user typed is the most likely place for
  /// credentials and personal data to appear, and it is the one category that
  /// cannot be judged from the widget tree alone, so it is masked unless an
  /// enclosing [SensitiveArea] explicitly reveals it.
  final bool maskTextInput;

  /// Returns what [element] says about its own subtree.
  ///
  /// [renderObject] is null for elements that do not create one.
  Sensitivity resolve(Element element, RenderObject? renderObject) {
    final widget = element.widget;
    if (widget is SensitiveArea) {
      return widget.isSensitive
          ? Sensitivity.sensitive
          : Sensitivity.notSensitive;
    }

    // Checked on the render object rather than on EditableText, because every
    // text-entry widget in the framework and in application code funnels into
    // this one render object, while the widgets wrapping it vary.
    if (maskTextInput && renderObject is RenderEditable) {
      return Sensitivity.sensitive;
    }

    return Sensitivity.inherit;
  }
}
