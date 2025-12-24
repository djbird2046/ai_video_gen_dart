import 'package:dio/dio.dart';

import '../../base_generator.dart';
import '../../model.dart';
import '../../utils/http_util.dart';
import '../../utils/payload_utils.dart';
import 'dto.dart';

const _defaultModel = WanXiangModelNames.wan2_6I2v;
const GeneratorCapabilities _wanxiangCapabilities = GeneratorCapabilities(
  resolutionsByModel: WanXiangModelConstraints.resolutionsByModel,
  durationsByModel: WanXiangModelConstraints.durationsByModel,
);

class WanXiangGenerator extends BaseHttpGenerator {
  WanXiangGenerator({required String apiKey, String? baseUrl, Dio? httpClient})
    : super(
        adapter: HttpProviderAdapter(
          defaultBaseUrl: baseUrl ?? 'https://dashscope.aliyuncs.com',
          startPath: '/api/v1/services/aigc/video-generation/video-synthesis',
          statusPath: (String requestId) => '/api/v1/tasks/$requestId',
          authHeader: (apiKey) => 'Bearer $apiKey',
          config: ProviderConfig(apiKey: apiKey, baseUrl: baseUrl),
          httpClient: httpClient,
          configureRequest: addDashscopeAsyncHeader,
        ),
      );

  @override
  String? get promptGuideUrl =>
      'https://bailian.console.aliyun.com/?tab=doc#/doc/?type=model&url=2865313';

  @override
  GeneratorCapabilities? get capabilities => _wanxiangCapabilities;

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
    final image = meta['img_url'] ?? meta['image'];
    if (image is! String || image.trim().isEmpty) {
      throw VideoGenException('WanXiang requires img_url or image in metadata');
    }

    final model =
        _normalizeText(request.model) ??
        _normalizeText(meta['model']) ??
        _defaultModel;
    final resolution = _normalizeText(meta['resolution'] ?? request.resolution);
    final duration = _parseInt(meta['duration'] ?? request.durationSeconds);
    _validateModelConstraints(model, resolution, duration);

    return request;
  }
}

Object _mapRequest(UnifiedVideoRequest request) {
  final meta = request.metadata ?? const <String, Object?>{};
  final model =
      _normalizeText(request.model) ??
      _normalizeText(meta['model']) ??
      _defaultModel;
  final image = meta['img_url'] ?? meta['image'];
  final audioUrl = _normalizeText(meta['audio_url']);

  final parameters = WanXiangParameters(
    resolution: _normalizeText(meta['resolution'] ?? request.resolution),
    duration: _parseInt(meta['duration'] ?? request.durationSeconds),
    promptExtend: _parseBool(meta['prompt_extend']),
    shotType: _normalizeText(meta['shot_type']),
    audio: audioUrl == null ? _parseBool(meta['audio']) : null,
    watermark: _parseBool(meta['watermark']),
    seed: _parseInt(request.seed ?? meta['seed']),
  );
  final parametersJson = parameters.toJson();

  final encodedImage = maybeEncodeFile(image, addDataPrefix: true);
  final input = WanXiangInput(
    prompt: request.prompt,
    negativePrompt: request.negativePrompt,
    imgUrl: encodedImage ?? image.toString(),
    audioUrl: audioUrl,
    template: _normalizeText(meta['template']),
  );

  final payload = WanXiangCreateRequest(
    model: model.toString(),
    input: input,
    parameters: parametersJson.isEmpty ? null : parameters,
  );

  return payload.toJson();
}

NormalizedResponse _mapResponse(Object? payload) {
  if (payload is! Map) return NormalizedResponse();
  final response = WanXiangResponse.fromJson(
    Map<String, dynamic>.from(payload),
  );

  final code = response.code;
  if (code != null && code.toString().isNotEmpty && code.toString() != '0') {
    return NormalizedResponse(
      status: GenerationStatus.failed,
      errorMessage: response.message,
      requestId: response.requestId,
    );
  }

  final output = response.output;
  final status = output?.taskStatus;

  return NormalizedResponse(
    requestId: output?.taskId ?? response.requestId,
    status: _mapStatus(status),
    videoUrl: output?.videoUrl,
    errorMessage: response.message,
  );
}

GenerationStatus _mapStatus(String? status) {
  switch (status) {
    case WanXiangTaskStatuses.pending:
      return GenerationStatus.queued;
    case WanXiangTaskStatuses.running:
      return GenerationStatus.processing;
    case WanXiangTaskStatuses.succeeded:
      return GenerationStatus.succeeded;
    case WanXiangTaskStatuses.failed:
    case WanXiangTaskStatuses.canceled:
    case WanXiangTaskStatuses.unknown:
      return GenerationStatus.failed;
    default:
      return GenerationStatus.processing;
  }
}

void _validateModelConstraints(
  String model,
  String? resolution,
  int? duration,
) {
  final supportedResolutions =
      WanXiangModelConstraints.resolutionsByModel[model];
  if (resolution != null && supportedResolutions != null) {
    if (!supportedResolutions.contains(resolution)) {
      final defaults =
          WanXiangModelConstraints.defaultResolutionByModel[model] ?? 'unknown';
      throw VideoGenException(
        'WanXiang resolution "$resolution" is not supported for "$model". '
        'Allowed: ${supportedResolutions.join(', ')}. Default: $defaults.',
      );
    }
  }

  final supportedDurations = WanXiangModelConstraints.durationsByModel[model];
  if (duration != null && supportedDurations != null) {
    if (!supportedDurations.contains(duration)) {
      final defaults =
          WanXiangModelConstraints.defaultDurationByModel[model] ?? 0;
      final defaultText = defaults == 0 ? 'unknown' : '${defaults}s';
      throw VideoGenException(
        'WanXiang duration "${duration}s" is not supported for "$model". '
        'Allowed: ${supportedDurations.join(', ')}. Default: $defaultText.',
      );
    }
  }
}

String? _normalizeText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _parseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
