import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../../base_generator.dart';
import '../../model.dart';
import '../../utils/dio_util.dart';
import '../../utils/http_util.dart';
import '../../utils/payload_utils.dart';
import 'dto.dart';

const List<String> _soraAspectRatios = [
  SoraAspectRatios.landscape16x9,
  SoraAspectRatios.portrait9x16,
  SoraAspectRatios.square,
  SoraAspectRatios.landscape4x3,
  SoraAspectRatios.portrait3x4,
];
const List<String> _soraResolutions = [
  SoraResolutions.p480,
  SoraResolutions.p720,
  SoraResolutions.p1080,
  SoraResolutions.k4,
];
const List<int> _soraDurations = [
  SoraDurations.fiveSeconds,
  SoraDurations.sixSeconds,
  SoraDurations.eightSeconds,
  SoraDurations.tenSeconds,
];
const GeneratorCapabilities _soraCapabilities = GeneratorCapabilities(
  aspectRatios: _soraAspectRatios,
  resolutions: _soraResolutions,
  durationsSeconds: _soraDurations,
);

class SoraGenerator extends BaseHttpGenerator implements ContentDownloader {
  SoraGenerator({
    required String apiKey,
    String? baseUrl,
    String? model,
    Dio? httpClient,
  }) : super(
         adapter: HttpProviderAdapter(
           defaultBaseUrl: baseUrl ?? 'https://api.openai.com',
           startPath: '/v1/videos',
           statusPath: (String requestId) => '/v1/videos/$requestId',
           authHeader: (String apiKey) => 'Bearer $apiKey',
           config: ProviderConfig(
             apiKey: apiKey,
             baseUrl: baseUrl,
             model: model ?? SoraModelNames.sora2,
           ),
           httpClient: httpClient,
         ),
       );

  @override
  String? get promptGuideUrl =>
      'https://cookbook.openai.com/examples/sora/sora2_prompting_guide';

  @override
  GeneratorCapabilities? get capabilities => _soraCapabilities;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    final processed = await preprocessRequest(request);
    final meta = processed.metadata ?? const <String, Object?>{};
    final inputReference =
        meta['input_reference'] ?? meta['inputReference'] ?? meta['reference'];

    if (inputReference != null) {
      final form = await _buildMultipartForm(
        processed,
        inputReference,
        adapter.config.model,
      );
      final raw = await _sendMultipart(
        adapter,
        '/v1/videos',
        form,
        apiKeyOverride: processed.apiKey,
      );
      return resultFromNormalized(_mapResponse(raw), raw);
    }

    final payload = _mapCreateRequest(processed, adapter.config.model).toJson();
    final raw = await _sendJson(
      adapter,
      '/v1/videos',
      payload,
      'POST',
      apiKeyOverride: processed.apiKey,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    final raw = await _sendJson(
      adapter,
      '/v1/videos/$requestId',
      null,
      'GET',
      apiKeyOverride: apiKeyOverride,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }

  /// Download completed video content (default variant=video).
  @override
  Future<Uint8List> downloadContent(
    String videoId, {
    String variant = SoraContentVariants.video,
    String? apiKeyOverride,
  }) async {
    final query = variant.isEmpty ? '' : '?variant=$variant';
    final response = await _sendBytes(
      adapter,
      '/v1/videos/$videoId/content$query',
      apiKeyOverride: apiKeyOverride,
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  /// List video jobs with optional pagination.
  Future<SoraListResponse> listVideos({
    int? limit,
    String? after,
    String? order,
    String? apiKeyOverride,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (after != null) params['after'] = after;
    if (order != null) params['order'] = order;
    final path = Uri(
      path: '/v1/videos',
      queryParameters: params.isEmpty ? null : params,
    ).toString();

    final raw = await _sendJson(
      adapter,
      path,
      null,
      'GET',
      apiKeyOverride: apiKeyOverride,
    );
    if (raw is Map) {
      return SoraListResponse.fromJson(Map<String, dynamic>.from(raw));
    }
    throw VideoGenException('Unexpected list response: $raw');
  }

  /// Delete a video by ID.
  Future<SoraDeleteResponse> deleteVideo(
    String videoId, {
    String? apiKeyOverride,
  }) async {
    final raw = await _sendJson(
      adapter,
      '/v1/videos/$videoId',
      null,
      'DELETE',
      apiKeyOverride: apiKeyOverride,
    );
    if (raw is Map) {
      return SoraDeleteResponse.fromJson(Map<String, dynamic>.from(raw));
    }
    throw VideoGenException('Unexpected delete response: $raw');
  }

  /// Remix a completed video with a new prompt.
  Future<GenerationResult> remix(
    String videoId, {
    required String prompt,
    String? apiKeyOverride,
  }) async {
    final payload = SoraRemixRequest(prompt: prompt).toJson();
    final raw = await _sendJson(
      adapter,
      '/v1/videos/$videoId/remix',
      payload,
      'POST',
      apiKeyOverride: apiKeyOverride,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }

  @override
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    final meta = request.metadata ?? const <String, Object?>{};
    final inputReference =
        meta['input_reference'] ?? meta['inputReference'] ?? meta['reference'];
    if (inputReference == null) {
      return request;
    }

    final inputSize = await _resolveInputReferenceSize(inputReference);
    if (inputSize == null) {
      return request;
    }

    final resolution = request.resolution?.trim();
    if (resolution == null || resolution.isEmpty) {
      return _copyWithResolution(request, inputSize);
    }

    final normalized = _resolveSize(resolution) ?? resolution;
    if (normalized != inputSize) {
      throw VideoGenException(
        'Sora input_reference size ($inputSize) must match resolution ($normalized)',
      );
    }

    return request;
  }
}

SoraCreateRequest _mapCreateRequest(
  UnifiedVideoRequest request,
  String? defaultModel,
) {
  final meta = request.metadata ?? const <String, Object?>{};
  final model =
      _normalizeText(meta['model']) ??
      _normalizeText(request.model) ??
      _normalizeText(meta['model_name']) ??
      _normalizeText(defaultModel);
  final size = _resolveSize(
    meta['size'] ?? request.resolution ?? meta['resolution'],
  );
  final seconds = _resolveSeconds(
    meta['seconds'] ??
        request.durationSeconds ??
        meta['duration_seconds'] ??
        meta['duration'],
  );

  return SoraCreateRequest(
    prompt: request.prompt,
    model: model,
    size: size,
    seconds: seconds,
  );
}

String? _normalizeText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _resolveSize(Object? raw) {
  final text = _normalizeText(raw);
  if (text == null) return null;
  final normalized = text.toLowerCase().replaceAll(' ', '');
  final sizePattern = RegExp(r'^\d{2,5}x\d{2,5}$');
  if (sizePattern.hasMatch(normalized)) return normalized;

  switch (normalized) {
    case '480p':
      return SoraSizes.p480;
    case '720p':
      return SoraSizes.p720;
    case '1080p':
      return SoraSizes.p1080;
    case '2160p':
    case '4k':
      return SoraSizes.k4;
    default:
      return text;
  }
}

int? _resolveSeconds(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

UnifiedVideoRequest _copyWithResolution(
  UnifiedVideoRequest request,
  String resolution,
) {
  return UnifiedVideoRequest(
    apiKey: request.apiKey,
    prompt: request.prompt,
    model: request.model,
    durationSeconds: request.durationSeconds,
    aspectRatio: request.aspectRatio,
    resolution: resolution,
    seed: request.seed,
    webhookUrl: request.webhookUrl,
    metadata: request.metadata,
    negativePrompt: request.negativePrompt,
    guidanceScale: request.guidanceScale,
    framesPerSecond: request.framesPerSecond,
    user: request.user,
  );
}

Future<FormData> _buildMultipartForm(
  UnifiedVideoRequest request,
  Object inputReference,
  String? defaultModel,
) async {
  final payload = _mapCreateRequest(request, defaultModel);
  final file = await _resolveInputReference(inputReference);
  final data = <String, Object?>{
    'prompt': payload.prompt,
    if (payload.model != null) 'model': payload.model,
    if (payload.size != null) 'size': payload.size,
    if (payload.seconds != null) 'seconds': payload.seconds.toString(),
    'input_reference': file,
  };
  return FormData.fromMap(data);
}

Future<MultipartFile> _resolveInputReference(Object inputReference) async {
  if (inputReference is MultipartFile) {
    return inputReference;
  }
  if (inputReference is File) {
    return MultipartFile.fromFile(
      inputReference.path,
      filename: _basename(inputReference.path),
    );
  }
  if (inputReference is String) {
    final normalizedPath = normalizeFilePath(inputReference);
    if (normalizedPath == null) {
      throw VideoGenException('Sora input_reference must be a local file path');
    }
    final file = File(normalizedPath);
    if (!file.existsSync()) {
      throw VideoGenException(
        'Sora input_reference not found: $normalizedPath',
      );
    }
    return MultipartFile.fromFile(file.path, filename: _basename(file.path));
  }
  throw VideoGenException('Sora input_reference must be a file path');
}

Future<String?> _resolveInputReferenceSize(Object inputReference) async {
  if (inputReference is String) {
    final normalizedPath = normalizeFilePath(inputReference);
    if (normalizedPath == null) {
      throw VideoGenException('Sora input_reference must be a local file path');
    }
    return _readImageSize(normalizedPath);
  }
  if (inputReference is File) {
    return _readImageSize(inputReference.path);
  }
  return null;
}

Future<String> _readImageSize(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw VideoGenException('Sora input_reference not found: $path');
  }
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw VideoGenException(
      'Sora input_reference must be a valid image: $path',
    );
  }
  return '${image.width}x${image.height}';
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isEmpty ? path : parts.last;
}

NormalizedResponse _mapResponse(Object? payload) {
  if (payload is! Map) return NormalizedResponse();
  final map = Map<String, dynamic>.from(payload);
  final response = SoraVideoResponse.fromJson(map);
  final generic = normalizeResponse(map);

  final status = response.status == null
      ? generic.status
      : normalizeStatus(response.status);
  final progress = response.progress;
  final normalizedProgress = progress == null
      ? null
      : progress > 1
      ? progress / 100
      : progress;
  final errorMessage =
      _extractErrorMessage(response.error) ??
      _extractErrorMessage(map['error']);

  final responseId = response.id;
  return NormalizedResponse(
    requestId: responseId == null || responseId.isEmpty
        ? generic.requestId
        : responseId,
    status: status ?? generic.status,
    progress: normalizedProgress ?? generic.progress,
    etaSeconds: generic.etaSeconds,
    videoUrl: generic.videoUrl,
    coverUrl: generic.coverUrl,
    errorMessage: errorMessage ?? generic.errorMessage,
  );
}

String? _extractErrorMessage(Object? error) {
  if (error == null) return null;
  if (error is String) return error;
  if (error is Map) {
    final message = error['message'];
    if (message != null) return message.toString();
  }
  return error.toString();
}

Future<Object?> _sendJson(
  HttpProviderAdapter adapter,
  String path,
  Object? body,
  String method, {
  String? apiKeyOverride,
}) async {
  return _sendRequest(
    adapter,
    path,
    method: method,
    body: body,
    apiKeyOverride: apiKeyOverride,
    includeJsonHeader: true,
  );
}

Future<Object?> _sendMultipart(
  HttpProviderAdapter adapter,
  String path,
  FormData body, {
  String? apiKeyOverride,
}) async {
  return _sendRequest(
    adapter,
    path,
    method: 'POST',
    body: body,
    apiKeyOverride: apiKeyOverride,
    includeJsonHeader: false,
  );
}

Future<Response<List<int>>> _sendBytes(
  HttpProviderAdapter adapter,
  String path, {
  String? apiKeyOverride,
}) async {
  final request = _buildRequest(
    adapter,
    path,
    method: 'GET',
    apiKeyOverride: apiKeyOverride,
    includeJsonHeader: false,
  );
  try {
    return await adapter.dio.request<List<int>>(
      request.resolvedUrl,
      options: Options(
        method: 'GET',
        headers: request.headers,
        responseType: ResponseType.bytes,
        validateStatus: (code) => code != null && code >= 200 && code < 300,
      ),
    );
  } on DioException catch (error) {
    throw VideoGenException(
      describeDioException(
        error,
        method: 'GET',
        path: path,
        resolvedUrl: request.resolvedUrl,
      ),
      cause: error,
    );
  }
}

Future<Object?> _sendRequest(
  HttpProviderAdapter adapter,
  String path, {
  required String method,
  required Object? body,
  String? apiKeyOverride,
  required bool includeJsonHeader,
}) async {
  final request = _buildRequest(
    adapter,
    path,
    method: method,
    apiKeyOverride: apiKeyOverride,
    includeJsonHeader: includeJsonHeader,
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
    body: null,
    payloadString: '',
    apiKey: apiKey,
  );
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
