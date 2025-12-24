import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../utils/http_util.dart';
import '../../utils/payload_utils.dart';

Future<String> prepareImage(String source) async {
  final bytes = await _loadImageBytes(source);
  final processedBytes = _processImage(bytes);
  return base64Encode(processedBytes);
}

Future<List<int>> _loadImageBytes(String source) async {
  final cleaned = source.startsWith('data:')
      ? source.substring(source.indexOf(',') + 1)
      : source;

  if (_looksLikeBase64(cleaned)) {
    try {
      return base64Decode(cleaned);
    } on FormatException {
      // fallback to path handling
    }
  }

  final path = normalizeFilePath(source);
  if (path != null) {
    final file = File(path);
    if (!await file.exists()) {
      throw VideoGenException('File not found: $path');
    }
    return file.readAsBytes();
  }

  try {
    return base64Decode(cleaned);
  } on FormatException {
    throw VideoGenException(
      'JiMeng expects a local image path or base64 string (JPEG/PNG)',
    );
  }
}

List<int> _processImage(List<int> bytes) {
  const maxBytes = 4928307; // ~4.7MB
  final data = Uint8List.fromList(bytes);
  final isJpeg = img.JpegDecoder().isValidFile(data);
  final isPng = img.PngDecoder().isValidFile(data);
  if (!isJpeg && !isPng) {
    throw VideoGenException('JiMeng only supports JPEG or PNG images');
  }

  final decoded = img.decodeImage(data);
  if (decoded == null) {
    throw VideoGenException('Unable to decode image');
  }
  img.Image image = decoded;

  if (image.width < 320 || image.height < 320) {
    throw VideoGenException(
      'Image must be at least 320x320 (got ${image.width}x${image.height})',
    );
  }

  image = _cropToAspect(image);
  image = _clampResolution(image);

  var encoded = _encode(image, isPng: isPng);

  // If still too large, iteratively downscale.
  while (encoded.length > maxBytes && image.width > 320 && image.height > 320) {
    final scale = sqrt(maxBytes / encoded.length) * 0.95;
    final newWidth = max(320, (image.width * scale).floor());
    final newHeight = max(320, (image.height * scale).floor());
    if (newWidth == image.width && newHeight == image.height) break;
    image = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.average,
    );
    encoded = _encode(image, isPng: isPng);
  }

  if (encoded.length > maxBytes) {
    throw VideoGenException(
      'Image exceeds 4.7MB even after resizing; try a smaller image',
    );
  }

  return encoded;
}

img.Image _cropToAspect(img.Image image) {
  final width = image.width;
  final height = image.height;
  final longSide = max(width, height);
  final shortSide = min(width, height);
  final ratio = longSide / shortSide;
  if (ratio <= 3) return image;

  if (width > height) {
    final targetWidth = (height * 3).round();
    final offsetX = ((width - targetWidth) / 2).round();
    return img.copyCrop(
      image,
      x: offsetX,
      y: 0,
      width: targetWidth,
      height: height,
    );
  } else {
    final targetHeight = (width * 3).round();
    final offsetY = ((height - targetHeight) / 2).round();
    return img.copyCrop(
      image,
      x: 0,
      y: offsetY,
      width: width,
      height: targetHeight,
    );
  }
}

img.Image _clampResolution(img.Image image) {
  const maxDim = 4096;
  var width = image.width;
  var height = image.height;
  if (width <= maxDim && height <= maxDim) return image;
  if (width > height) {
    height = (height * maxDim / width).round();
    width = maxDim;
  } else {
    width = (width * maxDim / height).round();
    height = maxDim;
  }
  return img.copyResize(
    image,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
}

List<int> _encode(img.Image image, {required bool isPng}) {
  return isPng ? img.encodePng(image) : img.encodeJpg(image, quality: 95);
}

double? extractProgressFromPayload(Object? payload) {
  return _searchProgress(payload, depth: 0);
}

double? _searchProgress(Object? value, {required int depth}) {
  if (value is Map) {
    final direct = _normalizeProgressValue(
      value['progress'] ??
          value['percent'] ??
          value['percentage'] ??
          value['task_progress'],
    );
    if (direct != null) return direct;

    if (depth >= 2) return null;
    for (final entry in value.values) {
      final nested = _searchProgress(entry, depth: depth + 1);
      if (nested != null) return nested;
    }
  }
  return null;
}

double? _normalizeProgressValue(Object? value) {
  if (value == null) return null;
  if (value is num) {
    final normalized = value.toDouble();
    return normalized > 1 ? normalized / 100 : normalized;
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return parsed > 1 ? parsed / 100 : parsed;
  }
  return null;
}

bool _looksLikeBase64(String value) {
  if (value.length < 16) return false;
  if (value.contains('/')) return true; // quick accept for common chars
  final pattern = RegExp(r'^[A-Za-z0-9+/\r\n]+=*$');
  return pattern.hasMatch(value) && value.length % 4 == 0;
}
