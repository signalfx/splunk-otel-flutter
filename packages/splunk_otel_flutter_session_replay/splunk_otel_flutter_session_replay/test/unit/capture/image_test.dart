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

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splunk_otel_flutter_session_replay/src/capture/descriptor/image_sampler.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/model/wireframe_node.dart';
import 'package:splunk_otel_flutter_session_replay/src/capture/walker/wireframe_walker.dart';

const Color _placeholder = Color(0xFF9E9E9E);

/// Every skeleton in the captured tree, in walk order.
List<WireframeSkeleton> _skeletons(WireframeNode node) => <WireframeSkeleton>[
  ...node.skeletons,
  for (final child in node.children) ..._skeletons(child),
];

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(alignment: Alignment.topLeft, child: child),
);

/// Builds a decoded image without touching the asset pipeline.
///
/// [top] fills the upper half and [bottom] the lower, so a test can tell an
/// averaged colour from a single sampled pixel.
ui.Image _image(int width, int height, {required Color top, Color? bottom}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final half = height / 2;

  canvas
    ..drawRect(
      Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        bottom == null ? height * 1.0 : half,
      ),
      Paint()..color = top,
    )
    ..drawRect(
      Rect.fromLTWH(0, half, width.toDouble(), half),
      Paint()..color = bottom ?? top,
    );

  return recorder.endRecording().toImageSync(width, height);
}

/// Captures once and lets the sampling the capture scheduled finish.
///
/// Reading pixels back needs a real event loop, which a widget test only has
/// inside [WidgetTester.runAsync].
Future<void> _sample(WidgetTester tester, WireframeWalker walker) =>
    tester.runAsync(() async {
      walker.capture();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

void main() {
  late WireframeWalker walker;

  setUp(() {
    walker = WireframeWalker();
  });

  group('ImageDescriptor', () {
    testWidgets('should stand in with a placeholder before sampling', (
      tester,
    ) async {
      final image = _image(40, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(RawImage(image: image, width: 40, height: 20)),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      // The colour is not known within the frame that first sees the image, so
      // the block preserves layout until it is.
      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 40, 20));
      expect(skeleton.color, _placeholder);
      expect(skeleton.isText, isFalse);
    });

    testWidgets('should report the average colour once sampled', (
      tester,
    ) async {
      final image = _image(
        40,
        20,
        top: const Color(0xFF000000),
        bottom: const Color(0xFFFFFFFF),
      );
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(RawImage(image: image, width: 40, height: 20)),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      // Half black, half white, so a mid grey rather than either half.
      expect(skeleton.color.r, closeTo(0.5, 0.05));
      expect(skeleton.color.g, closeTo(0.5, 0.05));
      expect(skeleton.color.b, closeTo(0.5, 0.05));
      expect(skeleton.effectiveOpacity, closeTo(1.0, 0.01));
    });

    testWidgets('should report where the image paints, not the whole box', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          RawImage(image: image, width: 200, height: 40, fit: BoxFit.contain),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      // A square image in a wide box is a 40 by 40 square in the middle, not a
      // 200 wide band.
      expect(skeleton.rect, const Rect.fromLTWH(80, 0, 40, 40));
    });

    testWidgets('should follow alignment within the box', (tester) async {
      final image = _image(20, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          RawImage(
            image: image,
            width: 200,
            height: 40,
            fit: BoxFit.contain,
            alignment: Alignment.centerRight,
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.rect, const Rect.fromLTWH(160, 0, 40, 40));
    });

    testWidgets('should cover the box when the image is tiled', (tester) async {
      final image = _image(20, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          RawImage(
            image: image,
            width: 200,
            height: 40,
            repeat: ImageRepeat.repeat,
          ),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 200, 40));
    });

    testWidgets('should report a tint rather than the sampled colour', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          RawImage(
            image: image,
            width: 20,
            height: 20,
            color: const Color(0xFFFF0000),
          ),
        ),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      // A tinted image keeps only its shape, which is how an icon is coloured.
      expect(skeleton.color.toARGB32(), const Color(0xFFFF0000).toARGB32());
    });

    testWidgets('should carry how much of the box the image covers', (
      tester,
    ) async {
      final image = _image(
        20,
        20,
        top: const Color(0xFF0000FF),
        bottom: const Color(0x00000000),
      );
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(RawImage(image: image, width: 20, height: 20)),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      // Half the image is transparent, so the block is half as opaque rather
      // than a solid blue rectangle over an area that is mostly empty.
      expect(skeleton.color.toARGB32() | 0xFF000000, 0xFF0000FF);
      expect(skeleton.effectiveOpacity, closeTo(0.5, 0.05));
    });

    testWidgets('should share one sampling between widgets showing the same '
        'image', (tester) async {
      final image = _image(20, 20, top: const Color(0xFF00FF00));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              RawImage(image: image, width: 20, height: 20),
              RawImage(image: image, width: 20, height: 20),
            ],
          ),
        ),
      );
      await _sample(tester, walker);

      final skeletons = _skeletons(walker.capture().single.root);

      expect(skeletons, hasLength(2));
      expect(skeletons.first.color.toARGB32(), skeletons.last.color.toARGB32());
      expect(skeletons.first.color, isNot(_placeholder));
    });

    testWidgets('should emit nothing while the image is still loading', (
      tester,
    ) async {
      // A placeholder block here would draw content the user cannot see yet.
      await tester.pumpWidget(_host(const RawImage(width: 40, height: 20)));

      expect(_skeletons(walker.capture().single.root), isEmpty);
    });
  });

  group('background images', () {
    setUp(resetImageSamples);

    testWidgets('should report a decoration image in its average colour', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFFFF0000));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _ProvidedImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 100, 100));
      expect(skeleton.color.toARGB32(), const Color(0xFFFF0000).toARGB32());
    });

    testWidgets('should leave the fill showing until the image resolves', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFFFF0000));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0000FF),
              image: DecorationImage(image: _ProvidedImage(image)),
            ),
          ),
        ),
      );

      // Guessing at the image would cover a colour that is actually known.
      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.color.toARGB32(), const Color(0xFF0000FF).toARGB32());
    });

    testWidgets('should report where a fitted decoration image lands', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFFFF0000));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _ProvidedImage(image),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      expect(skeleton.rect, const Rect.fromLTWH(80, 0, 40, 40));
    });
  });

  group('images and shaders inside a painter', () {
    setUp(resetImageSamples);

    testWidgets('should report a drawn image in its average colour', (
      tester,
    ) async {
      final image = _image(20, 20, top: const Color(0xFFFF0000));
      addTearDown(image.dispose);

      await tester.pumpWidget(
        _host(
          CustomPaint(size: const Size(50, 50), painter: _ImagePainter(image)),
        ),
      );
      await _sample(tester, walker);

      final skeleton = _skeletons(walker.capture().single.root).single;

      // The paint an image is drawn with carries no colour of its own, so
      // without sampling every picture would be reported as black.
      expect(skeleton.color.toARGB32(), const Color(0xFFFF0000).toARGB32());
    });

    testWidgets('should report a gradient shape neutrally, not as black', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(size: Size(50, 50), painter: _GradientPainter()),
        ),
      );

      final skeleton = _skeletons(walker.capture().single.root).single;

      // The shader holds the colours and cannot be read back, so the shape is
      // kept and the colour is admitted to be unknown.
      expect(skeleton.rect, const Rect.fromLTWH(0, 0, 50, 50));
      expect(skeleton.color.toARGB32(), unknownContentColor.toARGB32());
    });
  });
}

/// Serves an already decoded image, so a test needs no asset pipeline.
class _ProvidedImage extends ImageProvider<_ProvidedImage> {
  const _ProvidedImage(this.image);

  final ui.Image image;

  @override
  Future<_ProvidedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ProvidedImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _ProvidedImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
  );

  @override
  bool operator ==(Object other) =>
      other is _ProvidedImage && other.image == image;

  @override
  int get hashCode => image.hashCode;
}

class _ImagePainter extends CustomPainter {
  const _ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Offset.zero & size,
    Paint(),
  );

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => oldDelegate.image != image;
}

class _GradientPainter extends CustomPainter {
  const _GradientPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        const <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
      ),
  );

  @override
  bool shouldRepaint(_GradientPainter oldDelegate) => false;
}
