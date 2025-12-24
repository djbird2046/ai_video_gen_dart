// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JimengSubmitRequest _$JimengSubmitRequestFromJson(Map<String, dynamic> json) =>
    JimengSubmitRequest(
      reqKey: json['req_key'] as String? ?? 'jimeng_ti2v_v30_pro',
      prompt: json['prompt'] as String,
      binaryDataBase64: (json['binary_data_base64'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrls: (json['image_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      seed: (json['seed'] as num?)?.toInt(),
      frames: (json['frames'] as num?)?.toInt(),
      aspectRatio: json['aspect_ratio'] as String?,
    );

Map<String, dynamic> _$JimengSubmitRequestToJson(
  JimengSubmitRequest instance,
) => <String, dynamic>{
  'req_key': instance.reqKey,
  'prompt': instance.prompt,
  'binary_data_base64': ?instance.binaryDataBase64,
  'image_urls': ?instance.imageUrls,
  'seed': ?instance.seed,
  'frames': ?instance.frames,
  'aspect_ratio': ?instance.aspectRatio,
};

JimengStatusRequest _$JimengStatusRequestFromJson(Map<String, dynamic> json) =>
    JimengStatusRequest(
      reqKey: json['req_key'] as String? ?? 'jimeng_ti2v_v30_pro',
      taskId: json['task_id'] as String,
    );

Map<String, dynamic> _$JimengStatusRequestToJson(
  JimengStatusRequest instance,
) => <String, dynamic>{'req_key': instance.reqKey, 'task_id': instance.taskId};

JimengResponse _$JimengResponseFromJson(Map<String, dynamic> json) =>
    JimengResponse(
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      requestId: json['request_id'] as String?,
      data: json['data'] == null
          ? null
          : JimengTaskData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JimengResponseToJson(JimengResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'request_id': instance.requestId,
      'data': instance.data,
    };

JimengTaskData _$JimengTaskDataFromJson(Map<String, dynamic> json) =>
    JimengTaskData(
      taskId: json['task_id'] as String?,
      status: json['status'] as String?,
      videoUrl: json['video_url'] as String?,
    );

Map<String, dynamic> _$JimengTaskDataToJson(JimengTaskData instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'status': instance.status,
      'video_url': instance.videoUrl,
    };
