import 'dart:convert';

import 'package:dio/dio.dart';

import '../../base_generator.dart';
import '../../model.dart';
import '../../utils/dio_util.dart';
import '../../utils/http_util.dart';
import '../../utils/payload_utils.dart';
import 'dto.dart';

const List<String> _veoAspectRatios = [
  VeoAspectRatios.landscape16x9,
  VeoAspectRatios.portrait9x16,
];
const List<String> _veoResolutions = [
  VeoResolutions.p720,
  VeoResolutions.p1080,
];
const List<int> _veoDurations = [
  VeoDurations.fourSeconds,
  VeoDurations.fiveSeconds,
  VeoDurations.sixSeconds,
  VeoDurations.eightSeconds,
];
const GeneratorCapabilities _veoCapabilities = GeneratorCapabilities(
  aspectRatios: _veoAspectRatios,
  resolutions: _veoResolutions,
  durationsSeconds: _veoDurations,
);

class VeoGenerator extends BaseHttpGenerator {
  VeoGenerator({
    required String oauthToken,
    required this.projectId,
    required this.location,
    this.publisher = 'google',
    String? model,
    String? baseUrl,
    Dio? httpClient,
  }) : defaultModel = (model != null && model.trim().isNotEmpty)
           ? model.trim()
           : VeoModelIds.veo31Generate001,
       super(
         adapter: HttpProviderAdapter(
           defaultBaseUrl:
               baseUrl ?? 'https://$location-aiplatform.googleapis.com',
           startPath: '',
           statusPath: (_) => '',
           authHeader: (String token) => 'Bearer $token',
           config: ProviderConfig(
             apiKey: oauthToken,
             baseUrl: baseUrl,
             model: model,
           ),
           httpClient: httpClient,
         ),
       );

  final String projectId;
  final String location;
  final String publisher;
  final String defaultModel;

  @override
  String? get promptGuideUrl =>
      'https://docs.cloud.google.com/vertex-ai/generative-ai/docs/video/video-gen-prompt-guide';

  @override
  GeneratorCapabilities? get capabilities => _veoCapabilities;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    final processed = await preprocessRequest(request);
    final modelId = (processed.model ?? adapter.config.model ?? defaultModel)
        .trim();
    if (modelId.isEmpty) {
      throw VideoGenException('Veo model cannot be empty');
    }

    final payload = _mapPredictRequest(processed, modelId).toJson();
    final raw = await _sendJson(
      adapter,
      _predictPath(modelId),
      payload,
      'POST',
      apiKeyOverride: processed.apiKey,
    );
    final normalized = _mapStartResponse(raw);
    return resultFromNormalized(normalized, raw);
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    final modelId = adapter.config.model ?? defaultModel;
    final operationName = _normalizeOperationName(requestId, modelId);
    final payload = {'operationName': operationName};
    final raw = await _sendJson(
      adapter,
      _fetchPath(modelId),
      payload,
      'POST',
      apiKeyOverride: apiKeyOverride,
    );
    final normalized = _mapFetchResponse(raw, operationName);
    return resultFromNormalized(normalized, raw);
  }

  String _predictPath(String modelId) {
    return '/v1/projects/$projectId/locations/$location/publishers/$publisher/models/$modelId:predictLongRunning';
  }

  String _fetchPath(String modelId) {
    return '/v1/projects/$projectId/locations/$location/publishers/$publisher/models/$modelId:fetchPredictOperation';
  }

  String _normalizeOperationName(String requestId, String modelId) {
    if (requestId.contains('/operations/')) return requestId;
    return 'projects/$projectId/locations/$location/publishers/$publisher/models/$modelId/operations/$requestId';
  }
}

VeoPredictRequest _mapPredictRequest(
  UnifiedVideoRequest request,
  String modelId,
) {
  final meta = request.metadata ?? const <String, Object?>{};
  final image = _mediaFrom(meta['image'] ?? meta['input_image']);
  final lastFrame = _mediaFrom(meta['last_frame']);
  final video = _mediaFrom(meta['video']);
  final mask = _mediaFrom(
    meta['mask'],
    maskMode: meta['mask_mode']?.toString(),
  );
  final referenceImages = _referenceImagesFrom(meta['reference_images']);

  final generateAudioRaw = meta['generate_audio'];
  final generateAudio = generateAudioRaw is bool
      ? generateAudioRaw
      : modelId.startsWith('veo-3') ||
            modelId.startsWith('veo-3.0') ||
            modelId.startsWith('veo-3.1');

  final parameters = VeoParameters(
    aspectRatio: request.aspectRatio,
    compressionQuality: meta['compression_quality']?.toString(),
    durationSeconds: request.durationSeconds,
    enhancePrompt: _asBool(meta['enhance_prompt']),
    generateAudio: generateAudio,
    negativePrompt: request.negativePrompt,
    personGeneration: meta['person_generation']?.toString(),
    resizeMode: meta['resize_mode']?.toString(),
    resolution: request.resolution ?? meta['resolution']?.toString(),
    sampleCount: _asInt(meta['sample_count']),
    seed: request.seed,
    storageUri: meta['storage_uri']?.toString(),
  );

  final instance = VeoInstance(
    prompt: request.prompt,
    image: image,
    lastFrame: lastFrame,
    video: video,
    mask: mask,
    referenceImages: referenceImages,
  );
  return VeoPredictRequest(
    instances: <VeoInstance>[instance],
    parameters: parameters,
  );
}

List<VeoReferenceImage>? _referenceImagesFrom(Object? raw) {
  if (raw == null) return null;
  if (raw is List) {
    final list = <VeoReferenceImage>[];
    for (final entry in raw) {
      if (entry is VeoReferenceImage) {
        list.add(entry);
        continue;
      }
      if (entry is Map) {
        list.add(
          VeoReferenceImage(
            image: _mediaFrom(entry['image']),
            referenceType:
                entry['referenceType']?.toString() ??
                entry['reference_type']?.toString(),
          ),
        );
        continue;
      }
      if (entry is String) {
        list.add(
          VeoReferenceImage(
            image: _mediaFrom(entry),
            referenceType: VeoReferenceTypes.asset,
          ),
        );
      }
    }
    return list.isEmpty ? null : list;
  }
  return null;
}

VeoMedia? _mediaFrom(Object? raw, {String? maskMode}) {
  if (raw == null) return null;
  if (raw is VeoMedia) return raw;
  if (raw is Map) {
    return VeoMedia(
      bytesBase64Encoded:
          raw['bytesBase64Encoded']?.toString() ??
          raw['bytes_base64']?.toString(),
      gcsUri: raw['gcsUri']?.toString() ?? raw['gcs_uri']?.toString(),
      mimeType: raw['mimeType']?.toString() ?? raw['mime_type']?.toString(),
      maskMode: raw['maskMode']?.toString() ?? raw['mask_mode']?.toString(),
    );
  }
  if (raw is String) {
    final dataUrlPrefix = 'data:';
    if (raw.startsWith('gs://')) {
      return VeoMedia(
        gcsUri: raw,
        mimeType: _guessMime(raw),
        maskMode: maskMode,
      );
    }
    if (raw.startsWith(dataUrlPrefix)) {
      final split = raw.indexOf(';base64,');
      if (split > dataUrlPrefix.length) {
        final mime = raw.substring(dataUrlPrefix.length, split);
        final b64 = raw.substring(split + ';base64,'.length);
        return VeoMedia(
          bytesBase64Encoded: b64,
          mimeType: mime,
          maskMode: maskMode,
        );
      }
      return VeoMedia(bytesBase64Encoded: raw, maskMode: maskMode);
    }

    final encoded = maybeEncodeFile(raw);
    final mime = _guessMime(raw);
    if (encoded != null && encoded != raw) {
      return VeoMedia(
        bytesBase64Encoded: encoded,
        mimeType: mime,
        maskMode: maskMode,
      );
    }

    // Assume the caller passed base64.
    return VeoMedia(
      bytesBase64Encoded: raw,
      mimeType: mime,
      maskMode: maskMode,
    );
  }
  return null;
}

String? _guessMime(String pathOrData) {
  if (pathOrData.contains('/')) {
    return guessMime(pathOrData);
  }
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return null;
}

NormalizedResponse _mapStartResponse(Object? raw) {
  if (raw is! Map) return NormalizedResponse();
  final start = VeoOperationStart.fromJson(Map<String, dynamic>.from(raw));
  return NormalizedResponse(
    requestId: start.name ?? generateFallbackRequestId(),
    status: GenerationStatus.processing,
  );
}

NormalizedResponse _mapFetchResponse(Object? raw, String operationName) {
  if (raw is! Map) {
    return NormalizedResponse(
      requestId: operationName,
      status: GenerationStatus.processing,
    );
  }

  final response = VeoOperationResponse.fromJson(
    Map<String, dynamic>.from(raw),
  );

  final error = response.error;
  if (error != null && error.isNotEmpty) {
    final message = error['message']?.toString() ?? error.toString();
    return NormalizedResponse(
      requestId: response.name ?? operationName,
      status: GenerationStatus.failed,
      errorMessage: message,
    );
  }

  final done = response.done ?? false;
  final output = response.response;
  final videoUrl = output?.videos
      ?.firstWhere(
        (video) => video.gcsUri != null && video.gcsUri!.isNotEmpty,
        orElse: () => VeoVideoResult(),
      )
      .gcsUri;

  return NormalizedResponse(
    requestId: response.name ?? operationName,
    status: done ? GenerationStatus.succeeded : GenerationStatus.processing,
    videoUrl: videoUrl,
  );
}

Future<Object?> _sendJson(
  HttpProviderAdapter adapter,
  String path,
  Object? body,
  String method, {
  String? apiKeyOverride,
}) async {
  final request = _buildRequest(
    adapter,
    path,
    body: body,
    method: method,
    apiKeyOverride: apiKeyOverride,
    includeJsonHeader: true,
  );

  try {
    final response = await adapter.dio.request<String>(
      request.resolvedUrl,
      data: method.toUpperCase() == 'GET' ? null : body,
      options: Options(
        method: method,
        headers: request.headers,
        responseType: ResponseType.plain,
        validateStatus: (code) => code != null && code >= 200 && code < 300,
      ),
    );
    return _parseResponse(response);
  } on DioException catch (error) {
    throw VideoGenException(
      describeDioException(
        error,
        method: method,
        path: path,
        resolvedUrl: request.resolvedUrl,
      ),
      cause: error,
    );
  }
}

HttpRequestConfig _buildRequest(
  HttpProviderAdapter adapter,
  String path, {
  required Object? body,
  required String method,
  String? apiKeyOverride,
  required bool includeJsonHeader,
}) {
  final baseUrl = adapter.config.baseUrl?.trim().isNotEmpty == true
      ? adapter.config.baseUrl!
      : adapter.defaultBaseUrl;
  final apiKey = apiKeyOverride ?? adapter.config.apiKey;

  if (adapter.requireApiKey && (apiKey == null || apiKey.isEmpty)) {
    throw VideoGenException('Missing apiKey for provider');
  }

  final headers = <String, String>{
    if (includeJsonHeader) 'Content-Type': 'application/json',
    ...?adapter.config.extraHeaders,
  };
  if (apiKey != null && adapter.authHeader != null) {
    headers['Authorization'] = adapter.authHeader!(apiKey);
  }

  return HttpRequestConfig(
    resolvedUrl: Uri.parse(baseUrl).resolve(path).toString(),
    path: path,
    method: method,
    headers: headers,
    body: method.toUpperCase() == 'GET' ? null : body,
    payloadString: bodyAsString(body),
    apiKey: apiKey,
  );
}

String bodyAsString(Object? body) {
  if (body == null) return '';
  try {
    return jsonEncode(body);
  } catch (_) {
    return body.toString();
  }
}

Object? _parseResponse(Response<String> response) {
  final contentType = response.headers.value('content-type') ?? '';
  final data = response.data;
  if (data == null || data.isEmpty) {
    return null;
  }
  if (contentType.contains('application/json')) {
    return jsonDecode(data);
  }
  try {
    return jsonDecode(data);
  } catch (_) {
    return data;
  }
}
