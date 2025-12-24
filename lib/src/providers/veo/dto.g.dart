// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VeoMedia _$VeoMediaFromJson(Map<String, dynamic> json) => VeoMedia(
  bytesBase64Encoded: json['bytesBase64Encoded'] as String?,
  gcsUri: json['gcsUri'] as String?,
  mimeType: json['mimeType'] as String?,
  maskMode: json['maskMode'] as String?,
);

Map<String, dynamic> _$VeoMediaToJson(VeoMedia instance) => <String, dynamic>{
  'bytesBase64Encoded': ?instance.bytesBase64Encoded,
  'gcsUri': ?instance.gcsUri,
  'mimeType': ?instance.mimeType,
  'maskMode': ?instance.maskMode,
};

VeoReferenceImage _$VeoReferenceImageFromJson(Map<String, dynamic> json) =>
    VeoReferenceImage(
      image: json['image'] == null
          ? null
          : VeoMedia.fromJson(json['image'] as Map<String, dynamic>),
      referenceType: json['referenceType'] as String?,
    );

Map<String, dynamic> _$VeoReferenceImageToJson(VeoReferenceImage instance) =>
    <String, dynamic>{
      'image': ?instance.image?.toJson(),
      'referenceType': ?instance.referenceType,
    };

VeoInstance _$VeoInstanceFromJson(Map<String, dynamic> json) => VeoInstance(
  prompt: json['prompt'] as String?,
  image: json['image'] == null
      ? null
      : VeoMedia.fromJson(json['image'] as Map<String, dynamic>),
  lastFrame: json['lastFrame'] == null
      ? null
      : VeoMedia.fromJson(json['lastFrame'] as Map<String, dynamic>),
  video: json['video'] == null
      ? null
      : VeoMedia.fromJson(json['video'] as Map<String, dynamic>),
  mask: json['mask'] == null
      ? null
      : VeoMedia.fromJson(json['mask'] as Map<String, dynamic>),
  referenceImages: (json['referenceImages'] as List<dynamic>?)
      ?.map((e) => VeoReferenceImage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VeoInstanceToJson(
  VeoInstance instance,
) => <String, dynamic>{
  'prompt': ?instance.prompt,
  'image': ?instance.image?.toJson(),
  'lastFrame': ?instance.lastFrame?.toJson(),
  'video': ?instance.video?.toJson(),
  'mask': ?instance.mask?.toJson(),
  'referenceImages': ?instance.referenceImages?.map((e) => e.toJson()).toList(),
};

VeoParameters _$VeoParametersFromJson(Map<String, dynamic> json) =>
    VeoParameters(
      aspectRatio: json['aspectRatio'] as String?,
      compressionQuality: json['compressionQuality'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      enhancePrompt: json['enhancePrompt'] as bool?,
      generateAudio: json['generateAudio'] as bool?,
      negativePrompt: json['negativePrompt'] as String?,
      personGeneration: json['personGeneration'] as String?,
      resizeMode: json['resizeMode'] as String?,
      resolution: json['resolution'] as String?,
      sampleCount: (json['sampleCount'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      storageUri: json['storageUri'] as String?,
    );

Map<String, dynamic> _$VeoParametersToJson(VeoParameters instance) =>
    <String, dynamic>{
      'aspectRatio': ?instance.aspectRatio,
      'compressionQuality': ?instance.compressionQuality,
      'durationSeconds': ?instance.durationSeconds,
      'enhancePrompt': ?instance.enhancePrompt,
      'generateAudio': ?instance.generateAudio,
      'negativePrompt': ?instance.negativePrompt,
      'personGeneration': ?instance.personGeneration,
      'resizeMode': ?instance.resizeMode,
      'resolution': ?instance.resolution,
      'sampleCount': ?instance.sampleCount,
      'seed': ?instance.seed,
      'storageUri': ?instance.storageUri,
    };

VeoPredictRequest _$VeoPredictRequestFromJson(Map<String, dynamic> json) =>
    VeoPredictRequest(
      instances: (json['instances'] as List<dynamic>)
          .map((e) => VeoInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      parameters: json['parameters'] == null
          ? null
          : VeoParameters.fromJson(json['parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VeoPredictRequestToJson(VeoPredictRequest instance) =>
    <String, dynamic>{
      'instances': instance.instances.map((e) => e.toJson()).toList(),
      'parameters': ?instance.parameters?.toJson(),
    };

VeoOperationStart _$VeoOperationStartFromJson(Map<String, dynamic> json) =>
    VeoOperationStart(name: json['name'] as String?);

Map<String, dynamic> _$VeoOperationStartToJson(VeoOperationStart instance) =>
    <String, dynamic>{'name': ?instance.name};

VeoVideoResult _$VeoVideoResultFromJson(Map<String, dynamic> json) =>
    VeoVideoResult(
      gcsUri: json['gcsUri'] as String?,
      mimeType: json['mimeType'] as String?,
      bytesBase64Encoded: json['bytesBase64Encoded'] as String?,
    );

Map<String, dynamic> _$VeoVideoResultToJson(VeoVideoResult instance) =>
    <String, dynamic>{
      'gcsUri': ?instance.gcsUri,
      'mimeType': ?instance.mimeType,
      'bytesBase64Encoded': ?instance.bytesBase64Encoded,
    };

VeoPredictResponse _$VeoPredictResponseFromJson(Map<String, dynamic> json) =>
    VeoPredictResponse(
      raiMediaFilteredCount: (json['raiMediaFilteredCount'] as num?)?.toInt(),
      raiMediaFilteredReasons:
          (json['raiMediaFilteredReasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => VeoVideoResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VeoPredictResponseToJson(VeoPredictResponse instance) =>
    <String, dynamic>{
      'raiMediaFilteredCount': ?instance.raiMediaFilteredCount,
      'raiMediaFilteredReasons': ?instance.raiMediaFilteredReasons,
      'videos': ?instance.videos?.map((e) => e.toJson()).toList(),
    };

VeoOperationResponse _$VeoOperationResponseFromJson(
  Map<String, dynamic> json,
) => VeoOperationResponse(
  name: json['name'] as String?,
  done: json['done'] as bool?,
  error: json['error'] as Map<String, dynamic>?,
  response: json['response'] == null
      ? null
      : VeoPredictResponse.fromJson(json['response'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VeoOperationResponseToJson(
  VeoOperationResponse instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'done': ?instance.done,
  'error': ?instance.error,
  'response': ?instance.response?.toJson(),
};
