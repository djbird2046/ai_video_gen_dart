import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../model.dart';
import 'dio_util.dart';

abstract class ProviderAdapter {
  Future<GenerationResult> startGeneration(
    UnifiedVideoRequest request, {
    String? apiKeyOverride,
  });

  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  });
}

typedef RequestConfigurator =
    FutureOr<HttpRequestConfig> Function(HttpRequestConfig request);

class HttpRequestConfig {
  const HttpRequestConfig({
    required this.resolvedUrl,
    required this.path,
    required this.method,
    required this.headers,
    required this.body,
    required this.payloadString,
    this.apiKey,
  });

  final String resolvedUrl;
  final String path;
  final String method;
  final Map<String, String> headers;
  final Object? body;
  final String payloadString;
  final String? apiKey;

  HttpRequestConfig copyWith({
    String? resolvedUrl,
    String? path,
    String? method,
    Map<String, String>? headers,
    Object? body,
    String? payloadString,
    String? apiKey,
  }) {
    return HttpRequestConfig(
      resolvedUrl: resolvedUrl ?? this.resolvedUrl,
      path: path ?? this.path,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      payloadString: payloadString ?? this.payloadString,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class HttpProviderAdapter implements ProviderAdapter {
  HttpProviderAdapter({
    required this.defaultBaseUrl,
    required this.startPath,
    required this.statusPath,
    String? statusMethod,
    this.authHeader,
    this.requireApiKey = true,
    this.configureRequest,
    ProviderConfig? config,
    Dio? httpClient,
  }) : statusMethod = statusMethod ?? 'GET',
       config = config ?? const ProviderConfig(),
       dio = httpClient ?? createDefaultDio();

  final String defaultBaseUrl;
  final String startPath;
  final String Function(String requestId) statusPath;
  final String statusMethod;
  final String Function(String apiKey)? authHeader;
  final bool requireApiKey;
  final ProviderConfig config;
  final RequestConfigurator? configureRequest;
  final Dio dio;

  Future<Object?> sendStart(Object? payload, {String? apiKeyOverride}) {
    return _sendJson(startPath, payload, 'POST', apiKeyOverride);
  }

  Future<Object?> sendStatus(
    String requestId, {
    Object? payload,
    String? apiKeyOverride,
  }) {
    return _sendJson(
      statusPath(requestId),
      payload,
      statusMethod,
      apiKeyOverride,
    );
  }

  @override
  Future<GenerationResult> startGeneration(
    UnifiedVideoRequest request, {
    String? apiKeyOverride,
  }) async {
    final payload = defaultMapRequest(request, config.model);
    final raw = await sendStart(
      payload,
      apiKeyOverride: apiKeyOverride ?? request.apiKey,
    );
    return _toResult(raw);
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    final raw = await sendStatus(requestId, apiKeyOverride: apiKeyOverride);
    return _toResult(raw);
  }

  Future<Object?> _sendJson(
    String path,
    Object? body,
    String method,
    String? apiKeyOverride,
  ) async {
    final baseUrl = config.baseUrl?.trim().isNotEmpty == true
        ? config.baseUrl!
        : defaultBaseUrl;
    final apiKey = apiKeyOverride ?? config.apiKey;

    if (requireApiKey && (apiKey == null || apiKey.isEmpty)) {
      throw VideoGenException('Missing apiKey for provider');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?config.extraHeaders,
    };
    if (apiKey != null && authHeader != null) {
      headers['Authorization'] = authHeader!(apiKey);
    }

    final resolvedUrl = Uri.parse(baseUrl).resolve(path).toString();
    final payloadString = body == null ? '' : jsonEncode(body);

    var request = HttpRequestConfig(
      resolvedUrl: resolvedUrl,
      path: path,
      method: method,
      headers: headers,
      body: method.toUpperCase() == 'GET' ? null : body,
      payloadString: payloadString,
      apiKey: apiKey,
    );

    if (configureRequest != null) {
      request = await configureRequest!(request);
    }

    try {
      final response = await dio.request<String>(
        request.resolvedUrl,
        data: request.method.toUpperCase() == 'GET' ? null : request.body,
        options: Options(
          method: request.method,
          headers: request.headers,
          responseType: ResponseType.plain,
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      return _parseResponse(response);
    } on DioException catch (error) {
      final msg = describeDioException(
        error,
        method: method,
        path: path,
        resolvedUrl: request.resolvedUrl,
      );
      throw VideoGenException(msg, cause: error);
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

  GenerationResult _toResult(Object? rawPayload) {
    final normalized = normalizeResponse(rawPayload);
    return normalizedToResult(normalized, rawPayload);
  }
}

HttpRequestConfig signVolcengineRequest(
  HttpRequestConfig request, {
  required String secretKey,
  String region = 'cn-north-1',
  String service = 'cv',
  String? securityToken,
}) {
  final creds = _resolveAkSk(request.apiKey, secretKey);
  final signatureHeaders = _signVolcRequest(
    request.resolvedUrl,
    request.method,
    request.payloadString,
    creds.$1,
    creds.$2,
    region: region,
    service: service,
    securityToken: securityToken,
  );

  final mergedHeaders = {...request.headers, ...signatureHeaders};
  final isGet = request.method.toUpperCase() == 'GET';
  return request.copyWith(
    headers: mergedHeaders,
    body: isGet ? null : request.payloadString,
  );
}

HttpRequestConfig addDashscopeAsyncHeader(HttpRequestConfig request) {
  if (request.method.toUpperCase() != 'POST') return request;
  final mergedHeaders = {...request.headers, 'X-DashScope-Async': 'enable'};
  return request.copyWith(headers: mergedHeaders);
}

Object defaultMapRequest(UnifiedVideoRequest request, String? defaultModel) {
  final payload = <String, Object?>{
    'prompt': request.prompt,
    'model': request.model ?? defaultModel,
    'aspect_ratio': request.aspectRatio,
    'resolution': request.resolution,
    'duration_seconds': request.durationSeconds,
    'seed': request.seed,
    'webhook_url': request.webhookUrl,
    'metadata': request.metadata,
    'negative_prompt': request.negativePrompt,
    'guidance_scale': request.guidanceScale,
    'fps': request.framesPerSecond,
    'user': request.user,
  };
  payload.removeWhere((_, value) => value == null);
  return payload;
}

class NormalizedResponse {
  NormalizedResponse({
    this.requestId,
    this.status,
    this.progress,
    this.etaSeconds,
    this.videoUrl,
    this.coverUrl,
    this.errorMessage,
  });

  final String? requestId;
  final GenerationStatus? status;
  final double? progress;
  final int? etaSeconds;
  final String? videoUrl;
  final String? coverUrl;
  final String? errorMessage;
}

NormalizedResponse normalizeResponse(Object? rawPayload) {
  if (rawPayload == null) {
    return NormalizedResponse();
  }

  if (rawPayload is! Map) {
    return NormalizedResponse();
  }

  final payload = rawPayload.cast<Object?, Object?>();
  final statusText = payload['status'] ?? payload['state'] ?? payload['phase'];
  final status = normalizeStatus(statusText?.toString());
  final output = payload['output'];
  String? videoUrl;
  if (payload['video_url'] is String) {
    videoUrl = payload['video_url'] as String;
  } else if (output is Map && output['video_url'] is String) {
    videoUrl = output['video_url'] as String;
  }

  String? coverUrl;
  if (payload['cover_url'] is String) {
    coverUrl = payload['cover_url'] as String;
  } else if (payload['thumbnail'] is String) {
    coverUrl = payload['thumbnail'] as String;
  } else if (payload['preview'] is String) {
    coverUrl = payload['preview'] as String;
  }

  final progressValue =
      payload['progress'] ?? payload['percent'] ?? payload['percentage'];
  double? normalizedProgress;
  if (progressValue is num) {
    normalizedProgress = progressValue > 1
        ? progressValue / 100
        : progressValue.toDouble();
  }

  return NormalizedResponse(
    requestId: _pickRequestId(payload),
    status: status,
    progress: normalizedProgress,
    etaSeconds: _asInt(payload['eta_seconds']),
    videoUrl: videoUrl,
    coverUrl: coverUrl,
    errorMessage: payload['error']?.toString(),
  );
}

GenerationStatus normalizeStatus(String? status) {
  if (status == null || status.isEmpty) {
    return GenerationStatus.processing;
  }

  final normalized = status.toLowerCase();
  if (normalized == 'queued' ||
      normalized == 'pending' ||
      normalized == 'waiting') {
    return GenerationStatus.queued;
  }
  if (normalized == 'processing' ||
      normalized == 'in_progress' ||
      normalized == 'in-progress' ||
      normalized == 'running' ||
      normalized == 'working') {
    return GenerationStatus.processing;
  }
  if (normalized == 'streaming' || normalized == 'generating') {
    return GenerationStatus.streaming;
  }
  if (normalized == 'succeeded' ||
      normalized == 'success' ||
      normalized == 'completed' ||
      normalized == 'done') {
    return GenerationStatus.succeeded;
  }
  if (normalized == 'failed' ||
      normalized == 'error' ||
      normalized == 'canceled' ||
      normalized == 'cancelled') {
    return GenerationStatus.failed;
  }
  return GenerationStatus.processing;
}

String? _pickRequestId(Map<Object?, Object?> payload) {
  if (payload['id'] is String) return payload['id'] as String;
  if (payload['request_id'] is String) return payload['request_id'] as String;
  if (payload['task_id'] is String) return payload['task_id'] as String;
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

GenerationResult normalizedToResult(
  NormalizedResponse normalized,
  Object? rawPayload,
) {
  final requestId = normalized.requestId ?? generateFallbackRequestId();
  final status = normalized.status ?? GenerationStatus.processing;
  return GenerationResult(
    requestId: requestId,
    status: status,
    progress: normalized.progress,
    etaSeconds: normalized.etaSeconds,
    videoUrl: normalized.videoUrl,
    coverUrl: normalized.coverUrl,
    errorMessage: normalized.errorMessage,
    rawResponse: rawPayload,
  );
}

String generateFallbackRequestId() {
  final random = Random.secure();
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final entropy = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  return '$ts-$entropy';
}

class VideoGenException implements Exception {
  VideoGenException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'VideoGenException: $message';
}

/// Returns (accessKey, secretKey).
(String, String) _resolveAkSk(String? apiKey, String? secretKey) {
  String? ak = apiKey;
  String? sk = secretKey;
  if (apiKey != null && apiKey.contains(':')) {
    final parts = apiKey.split(':');
    ak = parts.first;
    sk = parts.length > 1 ? parts.sublist(1).join(':') : secretKey;
  }
  if (ak == null || ak.isEmpty || sk == null || sk.isEmpty) {
    throw VideoGenException(
      'Missing accessKey/secretKey for Volcengine signing',
    );
  }
  return (ak, sk);
}

Map<String, String> _signVolcRequest(
  String url,
  String method,
  String payload,
  String accessKey,
  String secretKey, {
  String region = 'cn-north-1',
  String service = 'cv',
  String? securityToken,
}) {
  final uri = Uri.parse(url);
  final canonicalQuery = _canonicalQuery(uri.queryParametersAll);
  final signingUrl = uri.replace(query: canonicalQuery).toString();
  final signingUri = Uri.parse(signingUrl);
  final now = DateTime.now().toUtc();
  final dateStamp =
      '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final timeStamp =
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  final amzDate = '${dateStamp}T${timeStamp}Z';

  final canonicalUri = signingUri.path.isEmpty ? '/' : signingUri.path;
  final payloadHash = sha256.convert(utf8.encode(payload)).toString();

  final headers = <String, String>{
    'content-type': 'application/json',
    'host': signingUri.host,
    'x-content-sha256': payloadHash,
    'x-date': amzDate,
    if (securityToken != null && securityToken.isNotEmpty)
      'x-security-token': securityToken,
  };
  final sortedHeaderKeys = headers.keys.toList()..sort();
  final canonicalHeaders =
      '${sortedHeaderKeys.map((key) => '$key:${headers[key]}').join('\n')}\n';
  final signedHeaders = sortedHeaderKeys.join(';');

  final canonicalRequest = [
    method.toUpperCase(),
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  final credentialScope = '$dateStamp/$region/$service/request';
  final stringToSign = [
    'HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256.convert(utf8.encode(canonicalRequest)).toString(),
  ].join('\n');

  final signingKey = _volcSigningKey(secretKey, dateStamp, region, service);
  final signature = Hmac(
    sha256,
    signingKey,
  ).convert(utf8.encode(stringToSign)).toString();

  final authorization =
      'HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

  return <String, String>{
    'Content-Type': 'application/json',
    'Host': uri.host,
    'X-Date': amzDate,
    'X-Content-Sha256': payloadHash,
    if (securityToken != null && securityToken.isNotEmpty)
      'X-Security-Token': securityToken,
    'Authorization': authorization,
  };
}

List<int> _volcSigningKey(
  String secretKey,
  String dateStamp,
  String region,
  String service,
) {
  final kDate = Hmac(
    sha256,
    utf8.encode(secretKey),
  ).convert(utf8.encode(dateStamp)).bytes;
  final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
  final kService = Hmac(sha256, kRegion).convert(utf8.encode(service)).bytes;
  final kSigning = Hmac(sha256, kService).convert(utf8.encode('request')).bytes;
  return kSigning;
}

String _canonicalQuery(Map<String, List<String>> params) {
  if (params.isEmpty) return '';
  final entries = <String>[];
  final sortedKeys = List<String>.of(params.keys)..sort();
  for (final key in sortedKeys) {
    final values = List<String>.of(params[key] ?? const <String>[]);
    values.sort();
    for (final value in values) {
      entries.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    }
  }
  return entries.join('&');
}
