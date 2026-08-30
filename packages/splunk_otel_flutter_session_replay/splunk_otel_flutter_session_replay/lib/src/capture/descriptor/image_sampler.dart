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

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Reduces images to a single colour, off the capture path.
///
/// A capture walk is synchronous from start to finish, so that every node in a
/// frame describes the same instant. Reading pixels back out of a decoded image
/// is asynchronous and can therefore never happen during one. The way round it
/// is to look at an image once, out of band, and cache what it came out as; the
/// walk then reads the cache and stays synchronous.
///
/// The cost of that is a frame or two where an image is not yet known. Callers
/// stand in a placeholder for it, which keeps the layout honest and only the
/// colour provisional.

/// Colour used for image content that has not been sampled yet, and for paint
/// whose colour cannot be known at all.
const Color unknownContentColor = Color(0xFF9E9E9E);

/// Edge length of the grid an image is reduced to before averaging.
///
/// Small enough that reading it back is trivial, large enough that the average
/// is not decided by whatever the sampler happens to pick when asked to scale a
/// photograph to a single pixel.
const int _sampleGrid = 8;

/// How many providers are remembered.
///
/// A provider is cached by value rather than by identity, so this holds a
/// bounded number of small keys rather than growing with every rebuild.
const int _maxProviderSamples = 64;

/// What an image reduces to, once it has been looked at.
class ImageSample {
  /// Creates a sample.
  const ImageSample({
    required this.color,
    required this.coverage,
    required this.size,
  });

  /// Average colour, weighted by how opaque each pixel is.
  final Color color;

  /// Mean alpha across the image, so a mostly transparent icon reports as
  /// mostly transparent rather than as a solid block.
  final double coverage;

  /// Pixel dimensions, needed to work out where a fitted image lands.
  final Size size;

  /// The colour to fill with, with coverage folded into its alpha.
  Color get fill => color.withValues(alpha: color.a * coverage);
}

/// Samples held against the decoded image, weakly.
///
/// Keyed on the decoded image rather than on the widget or the asset name: the
/// same decoded image is shared by every widget showing it, so it is sampled
/// once no matter how many places it appears in.
final Expando<ImageSample> _byImage = Expando<ImageSample>('splunkImageSample');

/// Images whose sampling has been started, so it is started only once.
final Expando<bool> _sampling = Expando<bool>('splunkImageSampling');

/// Samples held against an image provider.
///
/// A decoration names its image by provider rather than holding a decoded one,
/// and a provider is rebuilt constantly, so this is keyed by value. Insertion
/// order is the eviction order.
final Map<ImageProvider<Object>, ImageSample> _byProvider =
    <ImageProvider<Object>, ImageSample>{};

/// Providers whose resolution has been started.
final Set<ImageProvider<Object>> _resolving = <ImageProvider<Object>>{};

/// The sample for [image], starting one if this is the first sighting.
///
/// Returns null until the sampling finishes, which the caller stands in for.
ImageSample? sampleOf(ui.Image image) {
  final sample = _byImage[image];
  if (sample != null) {
    return sample;
  }

  _startSampling(image);

  return null;
}

/// The sample for the image [provider] names, resolving it if needed.
///
/// Resolution is deferred like sampling is: a provider that has not been loaded
/// yet would otherwise start a decode, or even a network fetch, from inside a
/// capture.
ImageSample? sampleOfProvider(
  ImageProvider<Object> provider,
  ImageConfiguration configuration,
) {
  final sample = _byProvider[provider];
  if (sample != null) {
    return sample;
  }

  if (_resolving.add(provider)) {
    scheduleMicrotask(() => _resolve(provider, configuration));
  }

  return null;
}

/// Forgets every cached sample. For tests, which must not inherit state.
@visibleForTesting
void resetImageSamples() {
  _byProvider.clear();
  _resolving.clear();
}

void _resolve(
  ImageProvider<Object> provider,
  ImageConfiguration configuration,
) {
  late ImageStreamListener listener;
  final stream = provider.resolve(configuration);

  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);

      final sample = _byImage[info.image];
      if (sample != null) {
        _remember(provider, sample);
        info.dispose();

        return;
      }

      // Kept alive across the read, then handed over: the decoration only lends
      // the image for the duration of the callback.
      final handle = info.image.clone();
      info.dispose();

      unawaited(
        _sample(handle).then((sample) {
          if (sample != null) {
            _remember(provider, sample);
          }
        }),
      );
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      _resolving.remove(provider);
    },
  );

  stream.addListener(listener);
}

void _remember(ImageProvider<Object> provider, ImageSample sample) {
  if (_byProvider.length >= _maxProviderSamples) {
    _byProvider.remove(_byProvider.keys.first);
  }

  _byProvider[provider] = sample;
}

void _startSampling(ui.Image image) {
  if (_sampling[image] ?? false) {
    return;
  }
  _sampling[image] = true;

  // Cloned because whatever is showing the image may dispose it while the read
  // is in flight, and deferred to a microtask so that even redrawing it at grid
  // size happens after the capture that asked for it has finished.
  final ui.Image handle;
  try {
    handle = image.clone();
  } catch (_) {
    return;
  }

  scheduleMicrotask(() async {
    final sample = await _sample(handle);
    if (sample != null) {
      _byImage[image] = sample;
    }
  });
}

/// Reads [handle] at grid size and disposes it.
Future<ImageSample?> _sample(ui.Image handle) async {
  final size = Size(handle.width.toDouble(), handle.height.toDouble());

  try {
    final recorder = ui.PictureRecorder();
    final grid = _sampleGrid.toDouble();
    Canvas(recorder, Rect.fromLTWH(0, 0, grid, grid)).drawImageRect(
      handle,
      Offset.zero & size,
      Rect.fromLTWH(0, 0, grid, grid),
      Paint()..filterQuality = FilterQuality.low,
    );

    final reduced = recorder.endRecording().toImageSync(
      _sampleGrid,
      _sampleGrid,
    );
    final bytes = await reduced.toByteData();
    reduced.dispose();

    if (bytes == null) {
      return null;
    }

    return _average(bytes, size);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'splunk_otel_flutter_session_replay',
        context: ErrorDescription(
          'while sampling an image for a session replay frame; it will be '
          'reported as a placeholder',
        ),
        silent: true,
      ),
    );

    return null;
  } finally {
    handle.dispose();
  }
}

/// Reduces raw pixels to one colour and a coverage fraction.
///
/// The bytes come back with colour already multiplied by alpha, so summing the
/// colour channels and dividing by the summed alpha yields the average of what
/// is actually visible, rather than an average that transparent pixels have
/// dragged towards black.
ImageSample _average(ByteData bytes, Size size) {
  var red = 0;
  var green = 0;
  var blue = 0;
  var alpha = 0;

  for (var offset = 0; offset + 3 < bytes.lengthInBytes; offset += 4) {
    red += bytes.getUint8(offset);
    green += bytes.getUint8(offset + 1);
    blue += bytes.getUint8(offset + 2);
    alpha += bytes.getUint8(offset + 3);
  }

  final pixels = bytes.lengthInBytes ~/ 4;
  if (pixels == 0 || alpha == 0) {
    return ImageSample(color: const Color(0x00000000), coverage: 0, size: size);
  }

  return ImageSample(
    color: Color.fromARGB(
      0xFF,
      (red * 0xFF / alpha).round().clamp(0, 0xFF),
      (green * 0xFF / alpha).round().clamp(0, 0xFF),
      (blue * 0xFF / alpha).round().clamp(0, 0xFF),
    ),
    coverage: alpha / (pixels * 0xFF),
    size: size,
  );
}

/// Rectangle an image lands in when drawn into [box].
///
/// Mirrors the arithmetic in `paintImage`, which is what decides where an image
/// sits inside the area it is given. Reporting the whole box instead would
/// colour the empty margins either side of a portrait photo in a square frame.
Rect fittedImageRect({
  required Size imageSize,
  required Rect box,
  required BoxFit? fit,
  required AlignmentGeometry alignment,
  double scale = 1.0,
  ImageRepeat repeat = ImageRepeat.noRepeat,
  Rect? centerSlice,
  bool matchTextDirection = false,
  TextDirection? textDirection,
}) {
  // A tiled or nine-patch image covers its box by construction, and both are
  // drawn in pieces that a single rectangle could not describe anyway.
  if (repeat != ImageRepeat.noRepeat || centerSlice != null) {
    return box;
  }

  final fitted = applyBoxFit(
    fit ?? BoxFit.scaleDown,
    imageSize / scale,
    box.size,
  );
  final destination = fitted.destination;

  final direction = textDirection ?? TextDirection.ltr;
  final resolved = alignment.resolve(direction);
  final flip = matchTextDirection && direction == TextDirection.rtl;

  final halfWidthDelta = (box.width - destination.width) / 2;
  final halfHeightDelta = (box.height - destination.height) / 2;

  return box.topLeft.translate(
        halfWidthDelta + (flip ? -resolved.x : resolved.x) * halfWidthDelta,
        halfHeightDelta + resolved.y * halfHeightDelta,
      ) &
      destination;
}
