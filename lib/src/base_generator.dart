import 'dart:typed_data';

import 'utils/http_util.dart';
import 'model.dart';

/// Shared interface for provider-specific generators.
abstract class VideoGenerator {
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request);

  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  });

  /// Provider name used for download filenames and logs.
  String get providerName;

  /// Optional official prompt guide URL for this provider.
  String? get promptGuideUrl;

  /// Optional supported capability metadata for this provider.
  GeneratorCapabilities? get capabilities;

  /// Preprocess or validate a request before sending.
  /// Default implementation is a no-op.
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    return request;
  }
}

/// Optional interface for providers that need authenticated content downloads.
abstract class ContentDownloader {
  Future<Uint8List> downloadContent(
    String requestId, {
    String variant = 'video',
    String? apiKeyOverride,
  });
}

abstract class BaseHttpGenerator implements VideoGenerator {
  BaseHttpGenerator({required this.adapter});

  final HttpProviderAdapter adapter;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    final processed = await preprocessRequest(request);
    return adapter.startGeneration(processed);
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) {
    return adapter.getStatus(requestId, apiKeyOverride: apiKeyOverride);
  }

  @override
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    return request;
  }

  @override
  String get providerName {
    final rawType = runtimeType.toString();
    var label = rawType;
    if (rawType.toLowerCase().endsWith('generator')) {
      label = rawType.substring(0, rawType.length - 'Generator'.length);
    }
    label = _sanitizeProviderLabel(label);
    return label.isEmpty ? 'VideoGen' : label;
  }

  @override
  String? get promptGuideUrl => null;

  @override
  GeneratorCapabilities? get capabilities => null;

  GenerationResult resultFromRaw(Object? rawPayload) {
    return normalizedToResult(normalizeResponse(rawPayload), rawPayload);
  }

  GenerationResult resultFromNormalized(
    NormalizedResponse normalized,
    Object? rawPayload,
  ) {
    return normalizedToResult(normalized, rawPayload);
  }
}

final _invalidFileNameChars = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

String _sanitizeProviderLabel(String label) {
  var sanitized = label.trim();
  sanitized = sanitized.replaceAll(_invalidFileNameChars, '-');
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), '-');
  sanitized = sanitized.replaceAll(RegExp(r'-+'), '-');
  sanitized = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');
  return sanitized;
}
