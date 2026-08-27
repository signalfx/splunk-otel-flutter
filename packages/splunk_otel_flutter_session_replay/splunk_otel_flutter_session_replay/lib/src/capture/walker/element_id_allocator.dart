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

/// Assigns identifiers that stay stable across frames for the same [Element].
///
/// A replay player needs to correlate a node between consecutive frames to
/// animate it rather than treat it as a new object. `Element.hashCode` is
/// unsuitable: it is not guaranteed unique and can collide across a large tree.
///
/// An [Expando] holds its keys weakly, so an element that leaves the tree is
/// collected normally and its identifier is simply never reused. That gives
/// stable identity without the allocator retaining any part of the widget tree.
class ElementIdAllocator {
  final Expando<String> _ids = Expando<String>('splunkWireframeNodeId');

  int _nextId = 0;

  /// Number of identifiers handed out so far.
  int get allocatedCount => _nextId;

  /// Returns the identifier for [element], allocating one on first sight.
  String idFor(Element element) => _ids[element] ??= '${_nextId++}';
}
