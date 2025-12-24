import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

/// Supported Veo model ids.
class VeoModelIds {
  VeoModelIds._();

  static const String veo20Generate001 = 'veo-2.0-generate-001';
  static const String veo20GenerateExp = 'veo-2.0-generate-exp';
  static const String veo20GeneratePreview = 'veo-2.0-generate-preview';
  static const String veo30Generate001 = 'veo-3.0-generate-001';
  static const String veo30FastGenerate001 = 'veo-3.0-fast-generate-001';
  static const String veo30GeneratePreview = 'veo-3.0-generate-preview';
  static const String veo30FastGeneratePreview =
      'veo-3.0-fast-generate-preview';
  static const String veo31Generate001 = 'veo-3.1-generate-001';
  static const String veo31FastGenerate001 = 'veo-3.1-fast-generate-001';
  static const String veo31GeneratePreview = 'veo-3.1-generate-preview';
  static const String veo31FastGeneratePreview =
      'veo-3.1-fast-generate-preview';
}

/// Common Veo aspect ratios.
class VeoAspectRatios {
  VeoAspectRatios._();

  static const String landscape16x9 = '16:9';
  static const String portrait9x16 = '9:16';
}

/// Common Veo resolution presets.
class VeoResolutions {
  VeoResolutions._();

  static const String p720 = '720p';
  static const String p1080 = '1080p';
}

/// Common Veo durations in seconds.
class VeoDurations {
  VeoDurations._();

  static const int fourSeconds = 4;
  static const int fiveSeconds = 5;
  static const int sixSeconds = 6;
  static const int eightSeconds = 8;
}

class VeoCompressionQualities {
  VeoCompressionQualities._();

  static const String optimized = 'optimized';
  static const String lossless = 'lossless';
}

class VeoPersonGeneration {
  VeoPersonGeneration._();

  static const String allowAdult = 'allow_adult';
  static const String dontAllow = 'dont_allow';
}

class VeoResizeModes {
  VeoResizeModes._();

  static const String pad = 'pad';
  static const String crop = 'crop';
}

class VeoReferenceTypes {
  VeoReferenceTypes._();

  static const String asset = 'asset';
  static const String style = 'style';
}

@JsonSerializable(includeIfNull: false)
class VeoMedia {
  VeoMedia({
    this.bytesBase64Encoded,
    this.gcsUri,
    this.mimeType,
    this.maskMode,
  });

  factory VeoMedia.fromJson(Map<String, dynamic> json) =>
      _$VeoMediaFromJson(json);

  final String? bytesBase64Encoded;
  final String? gcsUri;
  final String? mimeType;
  final String? maskMode;

  Map<String, dynamic> toJson() => _$VeoMediaToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VeoReferenceImage {
  VeoReferenceImage({this.image, this.referenceType});

  factory VeoReferenceImage.fromJson(Map<String, dynamic> json) =>
      _$VeoReferenceImageFromJson(json);

  final VeoMedia? image;
  final String? referenceType;

  Map<String, dynamic> toJson() => _$VeoReferenceImageToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VeoInstance {
  VeoInstance({
    this.prompt,
    this.image,
    this.lastFrame,
    this.video,
    this.mask,
    this.referenceImages,
  });

  factory VeoInstance.fromJson(Map<String, dynamic> json) =>
      _$VeoInstanceFromJson(json);

  final String? prompt;
  final VeoMedia? image;
  final VeoMedia? lastFrame;
  final VeoMedia? video;
  final VeoMedia? mask;
  final List<VeoReferenceImage>? referenceImages;

  Map<String, dynamic> toJson() => _$VeoInstanceToJson(this);
}

@JsonSerializable(includeIfNull: false)
class VeoParameters {
  VeoParameters({
    this.aspectRatio,
    this.compressionQuality,
    this.durationSeconds,
    this.enhancePrompt,
    this.generateAudio,
    this.negativePrompt,
    this.personGeneration,
    this.resizeMode,
    this.resolution,
    this.sampleCount,
    this.seed,
    this.storageUri,
  });

  factory VeoParameters.fromJson(Map<String, dynamic> json) =>
      _$VeoParametersFromJson(json);

  final String? aspectRatio;
  final String? compressionQuality;
  final int? durationSeconds;
  final bool? enhancePrompt;
  final bool? generateAudio;
  final String? negativePrompt;
  final String? personGeneration;
  final String? resizeMode;
  final String? resolution;
  final int? sampleCount;
  final int? seed;
  final String? storageUri;

  Map<String, dynamic> toJson() => _$VeoParametersToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VeoPredictRequest {
  VeoPredictRequest({required this.instances, this.parameters});

  factory VeoPredictRequest.fromJson(Map<String, dynamic> json) =>
      _$VeoPredictRequestFromJson(json);

  final List<VeoInstance> instances;
  final VeoParameters? parameters;

  Map<String, dynamic> toJson() => _$VeoPredictRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class VeoOperationStart {
  VeoOperationStart({this.name});

  factory VeoOperationStart.fromJson(Map<String, dynamic> json) =>
      _$VeoOperationStartFromJson(json);

  final String? name;

  Map<String, dynamic> toJson() => _$VeoOperationStartToJson(this);
}

@JsonSerializable(includeIfNull: false)
class VeoVideoResult {
  VeoVideoResult({this.gcsUri, this.mimeType, this.bytesBase64Encoded});

  factory VeoVideoResult.fromJson(Map<String, dynamic> json) =>
      _$VeoVideoResultFromJson(json);

  final String? gcsUri;
  final String? mimeType;
  final String? bytesBase64Encoded;

  Map<String, dynamic> toJson() => _$VeoVideoResultToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VeoPredictResponse {
  VeoPredictResponse({
    this.raiMediaFilteredCount,
    this.raiMediaFilteredReasons,
    this.videos,
  });

  factory VeoPredictResponse.fromJson(Map<String, dynamic> json) =>
      _$VeoPredictResponseFromJson(json);

  final int? raiMediaFilteredCount;
  final List<String>? raiMediaFilteredReasons;
  final List<VeoVideoResult>? videos;

  Map<String, dynamic> toJson() => _$VeoPredictResponseToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VeoOperationResponse {
  VeoOperationResponse({this.name, this.done, this.error, this.response});

  factory VeoOperationResponse.fromJson(Map<String, dynamic> json) =>
      _$VeoOperationResponseFromJson(json);

  final String? name;
  final bool? done;
  final Map<String, dynamic>? error;
  final VeoPredictResponse? response;

  Map<String, dynamic> toJson() => _$VeoOperationResponseToJson(this);
}
