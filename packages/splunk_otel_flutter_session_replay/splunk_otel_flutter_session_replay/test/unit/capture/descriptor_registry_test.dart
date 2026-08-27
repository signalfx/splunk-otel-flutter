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
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/descriptor_registry.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/element_descriptor.dart';

/// Stands in for an application render object that has no public type.
class _PrivateRenderBox extends RenderProxyBox {}

/// Public marker the learner can recognise [_PrivateRenderBox] by, mirroring
/// how a real private render object is spotted through a public supertype.
mixin _PublicMarker on RenderProxyBox {}

class _MarkedRenderBox extends RenderProxyBox with _PublicMarker {}

class _MarkerWidget extends SingleChildRenderObjectWidget {
  const _MarkerWidget();

  @override
  RenderObject createRenderObject(BuildContext context) => _MarkedRenderBox();
}

class _RecordingDescriptor extends ElementDescriptor {
  const _RecordingDescriptor();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DescriptorRegistry', () {
    group('tier one, render object type', () {
      test('should resolve a descriptor keyed on the render object type', () {
        final registry = DescriptorRegistry();
        final element = _FakeElement(const SizedBox());

        final descriptor = registry.resolve(
          element,
          RenderParagraph(
            const TextSpan(text: 'hello'),
            textDirection: TextDirection.ltr,
          ),
        );

        expect(descriptor, isNotNull);
      });

      test('should take precedence over a widget type match', () {
        const byRenderObject = _RecordingDescriptor();
        const byWidget = _RecordingDescriptor();
        final registry = DescriptorRegistry(
          renderObjectDescriptors: <Type, ElementDescriptor>{
            _PrivateRenderBox: byRenderObject,
          },
          widgetDescriptors: <Type, ElementDescriptor>{SizedBox: byWidget},
        );

        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _PrivateRenderBox(),
        );

        expect(resolved, same(byRenderObject));
      });
    });

    group('tier two, widget type', () {
      test('should resolve when the render object type is unknown', () {
        const descriptor = _RecordingDescriptor();
        final registry = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: <Type, ElementDescriptor>{SizedBox: descriptor},
        );

        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _PrivateRenderBox(),
        );

        expect(resolved, same(descriptor));
      });
    });

    group('tier three, learn on first sight', () {
      test('should return null when nothing matches', () {
        final registry = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        );

        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _PrivateRenderBox(),
        );

        expect(resolved, isNull);
      });

      test('should not learn when the learner does not recognise the '
          'render object', () {
        const descriptor = _RecordingDescriptor();
        final registry = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        );
        final learner = AncestorLearner(
          descriptor: descriptor,
          matches: (renderObject) => renderObject is _PublicMarker,
        );

        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _PrivateRenderBox(),
          pendingLearner: learner,
        );

        expect(resolved, isNull);
      });

      test('should learn a render object type from an armed ancestor', () {
        const descriptor = _RecordingDescriptor();
        final registry = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        );
        final learner = AncestorLearner(
          descriptor: descriptor,
          matches: (renderObject) => renderObject is _PublicMarker,
        );

        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _MarkedRenderBox(),
          pendingLearner: learner,
        );

        expect(resolved, same(descriptor));
      });

      test('should resolve the learned type without a learner afterwards', () {
        const descriptor = _RecordingDescriptor();
        final registry = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        );
        final learner = AncestorLearner(
          descriptor: descriptor,
          matches: (renderObject) => renderObject is _PublicMarker,
        );

        registry.resolve(
          _FakeElement(const SizedBox()),
          _MarkedRenderBox(),
          pendingLearner: learner,
        );
        final resolved = registry.resolve(
          _FakeElement(const SizedBox()),
          _MarkedRenderBox(),
        );

        expect(resolved, same(descriptor));
      });

      test('should arm a learner from the registered ancestor widget type', () {
        const descriptor = _RecordingDescriptor();
        final registry = DescriptorRegistry();
        final learner = AncestorLearner(
          descriptor: descriptor,
          matches: (renderObject) => renderObject is _PublicMarker,
        );
        registry.registerAncestorLearner(_MarkerWidget, learner);

        expect(registry.learnerFor(const _MarkerWidget()), same(learner));
        expect(registry.learnerFor(const SizedBox()), isNull);
      });

      test('should ship no learners by default', () {
        final registry = DescriptorRegistry();

        expect(registry.learnerFor(const _MarkerWidget()), isNull);
      });
    });

    group('isolation', () {
      test('should not leak learned types into another registry', () {
        const descriptor = _RecordingDescriptor();
        final learner = AncestorLearner(
          descriptor: descriptor,
          matches: (renderObject) => renderObject is _PublicMarker,
        );

        DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        ).resolve(
          _FakeElement(const SizedBox()),
          _MarkedRenderBox(),
          pendingLearner: learner,
        );

        final other = DescriptorRegistry(
          renderObjectDescriptors: const <Type, ElementDescriptor>{},
          widgetDescriptors: const <Type, ElementDescriptor>{},
        );

        expect(
          other.resolve(_FakeElement(const SizedBox()), _MarkedRenderBox()),
          isNull,
        );
      });
    });
  });
}

/// Minimal element that only has to answer `widget`, which is all the registry
/// reads.
class _FakeElement extends Element {
  _FakeElement(super.widget);

  @override
  bool get debugDoingBuild => false;

  @override
  void performRebuild() {
    super.performRebuild();
  }
}
