import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../../model.dart';
import '../../base_generator.dart';
import '../../utils/http_util.dart';
import '../../utils/payload_utils.dart';
import 'dto.dart';

const List<int> _klingDurations = [
  KlingDurations.fiveSeconds,
  KlingDurations.tenSeconds,
];
const GeneratorCapabilities _klingCapabilities = GeneratorCapabilities(
  durationsSeconds: _klingDurations,
);

class KlingGenerator extends BaseHttpGenerator {
  KlingGenerator({
    required String accessKey,
    String? secretKey,
    String? baseUrl,
    Dio? httpClient,
  }) : super(
         adapter: HttpProviderAdapter(
           defaultBaseUrl: baseUrl ?? 'https://api-beijing.klingai.com',
           startPath: '/v1/videos/image2video',
           statusPath: (String requestId) =>
               '/v1/videos/image2video/$requestId',
           authHeader: null,
           config: ProviderConfig(
             apiKey: accessKey,
             secretKey: secretKey,
             baseUrl: baseUrl,
           ),
           httpClient: httpClient,
           configureRequest: (request) =>
               _addKlingJwtHeader(request, fallbackSecretKey: secretKey),
         ),
       );

  @override
  String? get promptGuideUrl =>
      'https://docs.qingque.cn/d/home/eZQDKi7uTmtUr3iXnALzw6vxp';

  @override
  GeneratorCapabilities? get capabilities => _klingCapabilities;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    final processed = await preprocessRequest(request);
    final payload = _mapRequest(processed);
    final raw = await adapter.sendStart(
      payload,
      apiKeyOverride: request.apiKey,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    final raw = await adapter.sendStatus(
      requestId,
      apiKeyOverride: apiKeyOverride,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }

  @override
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    final meta = request.metadata ?? const <String, Object?>{};
    final image = meta['image'];
    final imageTail = meta['image_tail'];
    final staticMask = meta['static_mask'];
    final dynamicMasks = meta['dynamic_masks'];
    final cameraControl = meta['camera_control'];

    final duration = _parseInt(meta['duration'] ?? request.durationSeconds);
    if (duration != null && duration != 5 && duration != 10) {
      throw VideoGenException('Kling duration must be 5 or 10 seconds');
    }

    _validateImageConstraints(image, field: 'image');
    _validateImageConstraints(imageTail, field: 'image_tail');
    _validateImageConstraints(staticMask, field: 'static_mask');

    if (!_hasText(image) && !_hasText(imageTail)) {
      throw VideoGenException('Kling requires image or image_tail');
    }

    final hasMasks = _hasText(staticMask) || _hasDynamicMasks(dynamicMasks);
    final hasCameraControl = cameraControl is Map && cameraControl.isNotEmpty;
    if (hasMasks && !_hasText(image)) {
      throw VideoGenException('Kling requires image when using masks');
    }
    if (hasCameraControl && !_hasText(image)) {
      throw VideoGenException('Kling requires image when using camera_control');
    }
    if (_hasText(imageTail) && (hasMasks || hasCameraControl)) {
      throw VideoGenException(
        'Kling does not allow image_tail with masks or camera_control',
      );
    }
    if (hasMasks && hasCameraControl) {
      throw VideoGenException('Kling does not allow masks with camera_control');
    }

    if (dynamicMasks is List) {
      if (dynamicMasks.length > 6) {
        throw VideoGenException('dynamic_masks supports up to 6 items');
      }
      for (final entry in dynamicMasks.whereType<Map>()) {
        _validateImageConstraints(entry['mask'], field: 'dynamic_masks.mask');
        final trajectories = entry['trajectories'];
        if (trajectories is List &&
            (trajectories.length < 2 || trajectories.length > 77)) {
          throw VideoGenException(
            'dynamic_masks.trajectories must contain 2-77 points',
          );
        }
      }
    }

    _validateCameraControl(cameraControl);

    return request;
  }
}

Map<String, dynamic> _mapRequest(UnifiedVideoRequest request) {
  final meta = request.metadata ?? const <String, dynamic>{};
  final durationSeconds = request.durationSeconds;
  final metaDuration = meta['duration'];
  final duration = durationSeconds?.toString() ?? metaDuration?.toString();

  final modelName =
      _normalizeText(meta['model_name']) ??
      _normalizeText(request.model) ??
      _normalizeText(meta['model']);

  final payload = KlingCreateRequest(
    prompt: request.prompt,
    negativePrompt: request.negativePrompt,
    duration: duration,
    modelName: modelName,
    mode: meta['mode']?.toString(),
    cfgScale: _parseDouble(
      meta['cfg_scale'] ?? request.guidanceScale,
    )?.toDouble(),
    image: maybeEncodeFile(meta['image']),
    imageTail: maybeEncodeFile(meta['image_tail']),
    staticMask: maybeEncodeFile(meta['static_mask']),
    dynamicMasks: _mapDynamicMasks(meta['dynamic_masks']),
    cameraControl: _mapCameraControl(meta['camera_control']),
    callbackUrl: meta['callback_url']?.toString() ?? request.webhookUrl,
    externalTaskId: meta['external_task_id']?.toString(),
  );

  return payload.toJson();
}

NormalizedResponse _mapResponse(Object? payload) {
  if (payload is! Map) {
    return NormalizedResponse();
  }

  final response = KlingResponse.fromJson(Map<String, dynamic>.from(payload));
  if (response.code != null && response.code != 0) {
    return NormalizedResponse(
      status: GenerationStatus.failed,
      errorMessage: response.message,
      requestId: response.requestId,
    );
  }

  final data = response.data;
  final statusText = data?.taskStatus;
  final firstVideo = data?.taskResult?.videos?.isNotEmpty == true
      ? data!.taskResult!.videos!.first
      : null;
  final progress = _extractProgress(payload);

  return NormalizedResponse(
    requestId: data?.taskId ?? response.requestId,
    status: _mapStatus(statusText),
    progress: progress,
    videoUrl: firstVideo?.url,
    errorMessage: data?.taskStatusMsg ?? response.message,
  );
}

GenerationStatus _mapStatus(String? status) {
  switch (status) {
    case 'submitted':
      return GenerationStatus.queued;
    case 'processing':
      return GenerationStatus.processing;
    case 'succeed':
      return GenerationStatus.succeeded;
    case 'failed':
      return GenerationStatus.failed;
    default:
      return GenerationStatus.processing;
  }
}

KlingCameraControl? _mapCameraControl(Object? value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final type = map['type']?.toString();
  final config = map['config'];
  KlingCameraControlConfig? controlConfig;
  if (config is Map) {
    final cfgMap = Map<String, dynamic>.from(config);
    final parsed = KlingCameraControlConfig(
      horizontal: _parseDouble(cfgMap['horizontal']),
      vertical: _parseDouble(cfgMap['vertical']),
      pan: _parseDouble(cfgMap['pan']),
      tilt: _parseDouble(cfgMap['tilt']),
      roll: _parseDouble(cfgMap['roll']),
      zoom: _parseDouble(cfgMap['zoom']),
    );
    if (_hasCameraConfigValues(parsed)) {
      controlConfig = parsed;
    }
  }
  if (type != null && type != 'simple') {
    return KlingCameraControl(type: type);
  }
  if (type == null && controlConfig == null) return null;
  return KlingCameraControl(type: type, config: controlConfig);
}

double? _extractProgress(Object? payload) {
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

List<KlingDynamicMask>? _mapDynamicMasks(Object? value) {
  if (value is! List) return null;
  final results = <KlingDynamicMask>[];
  for (final entry in value) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final trajectories = map['trajectories'];
    List<KlingTrajectory>? parsedTrajectories;
    if (trajectories is List) {
      parsedTrajectories = trajectories
          .whereType<Map>()
          .map(
            (item) => KlingTrajectory(
              x: _parseInt(item['x']),
              y: _parseInt(item['y']),
            ),
          )
          .toList();
    }
    results.add(
      KlingDynamicMask(
        mask: maybeEncodeFile(map['mask']),
        trajectories: parsedTrajectories,
      ),
    );
  }
  return results.isEmpty ? null : results;
}

void _validateImageConstraints(Object? value, {required String field}) {
  if (value is! String || value.isEmpty) return;
  if (value.startsWith('data:')) {
    throw VideoGenException('$field must be base64 without a data: prefix');
  }
  final path = normalizeFilePath(value);
  if (path == null) return;

  final file = File(path);
  if (!file.existsSync()) {
    throw VideoGenException('File not found for $field: $path');
  }

  const maxBytes = 10 * 1024 * 1024;
  final size = file.lengthSync();
  if (size > maxBytes) {
    throw VideoGenException('$field exceeds 10MB limit: $path');
  }

  final bytes = file.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw VideoGenException('Unsupported image format for $field: $path');
  }
  if (decoded.width < 300 || decoded.height < 300) {
    throw VideoGenException(
      '$field must be at least 300x300 (got ${decoded.width}x${decoded.height})',
    );
  }
  final ratio = decoded.width / decoded.height;
  if (ratio < 0.4 || ratio > 2.5) {
    throw VideoGenException(
      '$field aspect ratio must be between 1:2.5 and 2.5:1 '
      '(got ${ratio.toStringAsFixed(2)})',
    );
  }
}

bool _hasText(Object? value) {
  if (value is! String) return false;
  return value.trim().isNotEmpty;
}

bool _hasDynamicMasks(Object? value) {
  if (value is! List) return false;
  return value.whereType<Map>().isNotEmpty;
}

String? _normalizeText(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

void _validateCameraControl(Object? value) {
  if (value is! Map) return;
  final map = Map<String, dynamic>.from(value);
  final type = map['type']?.toString();
  final config = map['config'];
  if (type != 'simple') return;
  if (config is! Map) {
    throw VideoGenException(
      'camera_control.config is required for simple type',
    );
  }
  final cfgMap = Map<String, dynamic>.from(config);
  final values = <double?>[
    _parseDouble(cfgMap['horizontal']),
    _parseDouble(cfgMap['vertical']),
    _parseDouble(cfgMap['pan']),
    _parseDouble(cfgMap['tilt']),
    _parseDouble(cfgMap['roll']),
    _parseDouble(cfgMap['zoom']),
  ];

  final nonZero = values.where((value) => value != null && value != 0).length;
  if (nonZero != 1) {
    throw VideoGenException(
      'camera_control.config must set exactly one non-zero value for simple type',
    );
  }

  for (final value in values.whereType<double>()) {
    if (value < -10 || value > 10) {
      throw VideoGenException(
        'camera_control.config values must be between -10 and 10',
      );
    }
  }
}

bool _hasCameraConfigValues(KlingCameraControlConfig config) {
  return config.horizontal != null ||
      config.vertical != null ||
      config.pan != null ||
      config.tilt != null ||
      config.roll != null ||
      config.zoom != null;
}

HttpRequestConfig _addKlingJwtHeader(
  HttpRequestConfig request, {
  String? fallbackSecretKey,
}) {
  final resolved = _resolveKlingKeys(request.apiKey, fallbackSecretKey);
  final token = _buildKlingJwtToken(
    accessKey: resolved.$1,
    secretKey: resolved.$2,
  );
  final headers = Map<String, String>.from(request.headers);
  headers['Authorization'] = 'Bearer $token';
  return request.copyWith(headers: headers);
}

(String, String) _resolveKlingKeys(String? apiKey, String? fallbackSecretKey) {
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw VideoGenException('Missing accessKey for Kling');
  }

  var accessKey = apiKey.trim();
  String? secretKey = fallbackSecretKey;
  if (accessKey.contains(':')) {
    final parts = accessKey.split(':');
    accessKey = parts.first.trim();
    final inlineSecret = parts.sublist(1).join(':').trim();
    if (inlineSecret.isNotEmpty) {
      secretKey = inlineSecret;
    }
  }

  if (accessKey.isEmpty) {
    throw VideoGenException('Missing accessKey for Kling');
  }
  if (secretKey == null || secretKey.trim().isEmpty) {
    throw VideoGenException('Missing secretKey for Kling');
  }

  return (accessKey, secretKey.trim());
}

String _buildKlingJwtToken({
  required String accessKey,
  required String secretKey,
  Duration ttl = const Duration(minutes: 30),
}) {
  final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final payload = {
    'iss': accessKey,
    'exp': nowSeconds + ttl.inSeconds,
    'nbf': nowSeconds - 5,
  };

  final headerSegment = _base64UrlEncode(utf8.encode(jsonEncode(header)));
  final payloadSegment = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
  final signingInput = '$headerSegment.$payloadSegment';
  final signatureBytes = Hmac(
    sha256,
    utf8.encode(secretKey),
  ).convert(utf8.encode(signingInput));
  final signatureSegment = _base64UrlEncode(signatureBytes.bytes);

  return '$signingInput.$signatureSegment';
}

String _base64UrlEncode(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

double? _parseDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
