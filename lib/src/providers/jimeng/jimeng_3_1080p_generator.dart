import 'package:dio/dio.dart';

import '../../model.dart';
import '../../base_generator.dart';
import '../../utils/http_util.dart';
import 'exception.dart';
import 'dto.dart';
import 'shared.dart';

const String _jimeng3ReqKey1080p = 'jimeng_i2v_first_v30_1080';
const String _jimeng3PromptGuideUrl =
    'https://www.volcengine.com/docs/85621/1792707';
const List<String> _jimengAspectRatios = [
  JimengAspectRatios.landscape16x9,
  JimengAspectRatios.landscape4x3,
  JimengAspectRatios.square,
  JimengAspectRatios.portrait3x4,
  JimengAspectRatios.portrait9x16,
  JimengAspectRatios.ultraWide21x9,
];
const List<int> _jimengDurations = [
  JimengDurations.fiveSeconds,
  JimengDurations.tenSeconds,
];
const GeneratorCapabilities _jimengCapabilities = GeneratorCapabilities(
  aspectRatios: _jimengAspectRatios,
  durationsSeconds: _jimengDurations,
  sizesByAspectRatio: JimengAspectRatios.resolutions,
);

class JiMeng3RequestOptions {
  JiMeng3RequestOptions({required this.image, this.seed, this.frames});

  /// Path, file:// URI, or base64 string (without data: prefix).
  final String image;
  final int? seed;
  final int? frames;
}

class JiMeng3P1080Generator extends BaseHttpGenerator {
  JiMeng3P1080Generator({
    required String accessKey,
    required this.secretAccessKey,
    required this.options,
    this.region = 'cn-north-1',
    this.service = 'cv',
    String? baseUrl,
    Dio? httpClient,
    String? reqKeyOverride,
  }) : reqKey = reqKeyOverride ?? _jimeng3ReqKey1080p,
       super(
         adapter: HttpProviderAdapter(
           defaultBaseUrl: baseUrl ?? 'https://visual.volcengineapi.com',
           startPath: '/?Action=CVSync2AsyncSubmitTask&Version=2022-08-31',
           statusPath: (_) =>
               '/?Action=CVSync2AsyncGetResult&Version=2022-08-31',
           statusMethod: 'POST',
           config: ProviderConfig(
             apiKey: accessKey,
             secretKey: secretAccessKey,
             baseUrl: baseUrl,
           ),
           configureRequest: (request) => signVolcengineRequest(
             request,
             secretKey: secretAccessKey,
             region: region,
             service: service,
           ),
           httpClient: httpClient,
         ),
       );

  final JiMeng3RequestOptions options;
  final String secretAccessKey;
  final String region;
  final String service;
  final String reqKey;

  @override
  String get providerName => 'JiMeng3_1080p';

  @override
  String? get promptGuideUrl => _jimeng3PromptGuideUrl;

  @override
  GeneratorCapabilities? get capabilities => _jimengCapabilities;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    if (request.prompt.isEmpty) {
      throw VideoGenException('JiMeng 3.0 requires a non-empty prompt');
    }

    final processedImage = await prepareImage(options.image);
    final payload = _mapRequest(request, processedImage, options, reqKey);
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
      payload: _mapStatusRequest(requestId, reqKey),
      apiKeyOverride: apiKeyOverride,
    );
    return resultFromNormalized(_mapResponse(raw), raw);
  }
}

Map<String, dynamic> _mapRequest(
  UnifiedVideoRequest request,
  String base64Image,
  JiMeng3RequestOptions options,
  String reqKey,
) {
  final frames =
      options.frames ??
      (request.durationSeconds != null
          ? request.durationSeconds! * 24 + 1
          : null);

  final payload = JimengSubmitRequest(
    reqKey: reqKey,
    prompt: request.prompt,
    binaryDataBase64: <String>[base64Image],
    seed: request.seed ?? options.seed,
    frames: frames,
  );

  return payload.toJson();
}

Map<String, dynamic> _mapStatusRequest(String taskId, String reqKey) {
  return JimengStatusRequest(reqKey: reqKey, taskId: taskId).toJson();
}

NormalizedResponse _mapResponse(Object? payload) {
  if (payload is! Map) return NormalizedResponse();

  final response = JimengResponse.fromJson(Map<String, dynamic>.from(payload));

  final code = response.code;
  if (code != null && code != 10000) {
    final errorMsg = JimengErrors.describe(code, response.message);
    return NormalizedResponse(
      status: GenerationStatus.failed,
      errorMessage: errorMsg,
      requestId: response.requestId,
    );
  }

  final data = response.data;
  final progress = extractProgressFromPayload(payload);

  return NormalizedResponse(
    requestId: data?.taskId ?? response.requestId,
    status: _mapStatus(data?.status),
    progress: progress,
    videoUrl: data?.videoUrl,
    errorMessage: response.message,
  );
}

GenerationStatus _mapStatus(String? status) {
  if (status == null || status.trim().isEmpty) {
    return GenerationStatus.queued;
  }
  switch (status) {
    case 'in_queue':
      return GenerationStatus.queued;
    case 'generating':
      return GenerationStatus.processing;
    case 'done':
      return GenerationStatus.succeeded;
    case 'failed':
    case 'not_found':
    case 'expired':
      return GenerationStatus.failed;
    default:
      return GenerationStatus.processing;
  }
}
