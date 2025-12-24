import 'package:dio/dio.dart';
import '../../model.dart';
import '../../base_generator.dart';
import '../../utils/http_util.dart';
import 'exception.dart';
import 'dto.dart';
import 'shared.dart';

const String _jimeng3ProReqKey = 'jimeng_ti2v_v30_pro';
const String _jimeng3ProPromptGuideUrl =
    'https://www.volcengine.com/docs/85621/1783678';
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

class JiMengRequestOptions {
  JiMengRequestOptions({
    required this.image,
    this.reqKey,
    this.seed,
    this.frames,
  });

  /// Path, file:// URI, or base64 string (without data: prefix).
  final String image;
  final String? reqKey;
  final int? seed;
  final int? frames;
}

class JiMeng3ProGenerator extends BaseHttpGenerator {
  JiMeng3ProGenerator({
    required String accessKey,
    required this.secretAccessKey,
    required this.options,
    this.region = 'cn-north-1',
    this.service = 'cv',
    String? baseUrl,
    Dio? httpClient,
  }) : super(
         adapter: HttpProviderAdapter(
           defaultBaseUrl: baseUrl ?? 'https://visual.volcengineapi.com',
           startPath: '/?Action=CVSync2AsyncSubmitTask&Version=2022-08-31',
           statusPath: (String requestId) =>
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

  final JiMengRequestOptions options;
  final String secretAccessKey;
  final String region;
  final String service;

  @override
  String get providerName => 'JiMeng3_Pro';

  @override
  String? get promptGuideUrl => _jimeng3ProPromptGuideUrl;

  @override
  GeneratorCapabilities? get capabilities => _jimengCapabilities;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    final processedImage = await prepareImage(options.image);
    final reqKey = options.reqKey ?? _jimeng3ProReqKey;
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
    final reqKey = options.reqKey ?? _jimeng3ProReqKey;
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
  JiMengRequestOptions options,
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
    aspectRatio: request.aspectRatio,
  );

  return payload.toJson();
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
  final status = data?.status;
  final progress = extractProgressFromPayload(payload);

  return NormalizedResponse(
    requestId: data?.taskId ?? response.requestId,
    status: _mapStatus(status),
    progress: progress,
    videoUrl: data?.videoUrl,
    errorMessage: response.message,
  );
}

Map<String, dynamic> _mapStatusRequest(String requestId, String reqKey) {
  return JimengStatusRequest(reqKey: reqKey, taskId: requestId).toJson();
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
