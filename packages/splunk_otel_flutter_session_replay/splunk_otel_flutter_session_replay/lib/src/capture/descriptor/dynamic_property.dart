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

/// Reads a property that exists on a render object whose type cannot be named.
///
/// Several of Flutter's render objects are private classes with public members,
/// `_RenderColoredBox.color` among them. The member is reachable, but only
/// through a dynamic selector, because there is no nameable static type that
/// declares it.
///
/// A dynamic member read is the one form of name-based access that survives
/// release-mode obfuscation. The obfuscator rewrites declarations and dynamic
/// call sites through the same mapping, so the selector still resolves; this is
/// what separates it from `runtimeType.toString()`, which is compared against a
/// source literal that is not rewritten with it.
///
/// [read] must contain the dynamic access itself so the selector is fixed at
/// compile time:
///
/// ```dart
/// final color = readUnnameable<Color>(() => (renderObject as dynamic).color);
/// ```
///
/// Returns null when the member is absent or has an unexpected type, which is
/// what happens if a future Flutter version renames or removes it. Callers are
/// expected to degrade gracefully rather than drop the frame.
T? readUnnameable<T extends Object>(T Function() read) {
  try {
    return read();
  } on NoSuchMethodError {
    return null;
  } on TypeError {
    return null;
  }
}
