// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WanXiangCreateRequest _$WanXiangCreateRequestFromJson(
  Map<String, dynamic> json,
) => WanXiangCreateRequest(
  model: json['model'] as String,
  input: WanXiangInput.fromJson(json['input'] as Map<String, dynamic>),
  parameters: json['parameters'] == null
      ? null
      : WanXiangParameters.fromJson(json['parameters'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WanXiangCreateRequestToJson(
  WanXiangCreateRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'input': instance.input,
  'parameters': ?instance.parameters,
};

WanXiangInput _$WanXiangInputFromJson(Map<String, dynamic> json) =>
    WanXiangInput(
      prompt: json['prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
      imgUrl: json['img_url'] as String,
      audioUrl: json['audio_url'] as String?,
      template: json['template'] as String?,
    );

Map<String, dynamic> _$WanXiangInputToJson(WanXiangInput instance) =>
    <String, dynamic>{
      'prompt': ?instance.prompt,
      'negative_prompt': ?instance.negativePrompt,
      'img_url': instance.imgUrl,
      'audio_url': ?instance.audioUrl,
      'template': ?instance.template,
    };

WanXiangParameters _$WanXiangParametersFromJson(Map<String, dynamic> json) =>
    WanXiangParameters(
      resolution: json['resolution'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      promptExtend: json['prompt_extend'] as bool?,
      shotType: json['shot_type'] as String?,
      audio: json['audio'] as bool?,
      watermark: json['watermark'] as bool?,
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WanXiangParametersToJson(WanXiangParameters instance) =>
    <String, dynamic>{
      'resolution': ?instance.resolution,
      'duration': ?instance.duration,
      'prompt_extend': ?instance.promptExtend,
      'shot_type': ?instance.shotType,
      'audio': ?instance.audio,
      'watermark': ?instance.watermark,
      'seed': ?instance.seed,
    };

WanXiangResponse _$WanXiangResponseFromJson(Map<String, dynamic> json) =>
    WanXiangResponse(
      output: json['output'] == null
          ? null
          : WanXiangOutput.fromJson(json['output'] as Map<String, dynamic>),
      requestId: json['request_id'] as String?,
      code: json['code'],
      message: json['message'] as String?,
      usage: json['usage'] == null
          ? null
          : WanXiangUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WanXiangResponseToJson(WanXiangResponse instance) =>
    <String, dynamic>{
      'output': instance.output,
      'request_id': instance.requestId,
      'code': instance.code,
      'message': instance.message,
      'usage': instance.usage,
    };

WanXiangOutput _$WanXiangOutputFromJson(Map<String, dynamic> json) =>
    WanXiangOutput(
      taskId: json['task_id'] as String?,
      taskStatus: json['task_status'] as String?,
      submitTime: json['submit_time'] as String?,
      scheduledTime: json['scheduled_time'] as String?,
      endTime: json['end_time'] as String?,
      origPrompt: json['orig_prompt'] as String?,
      actualPrompt: json['actual_prompt'] as String?,
      videoUrl: json['video_url'] as String?,
    );

Map<String, dynamic> _$WanXiangOutputToJson(WanXiangOutput instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'submit_time': instance.submitTime,
      'scheduled_time': instance.scheduledTime,
      'end_time': instance.endTime,
      'orig_prompt': instance.origPrompt,
      'actual_prompt': instance.actualPrompt,
      'video_url': instance.videoUrl,
    };

WanXiangUsage _$WanXiangUsageFromJson(Map<String, dynamic> json) =>
    WanXiangUsage(
      duration: (json['duration'] as num?)?.toInt(),
      inputVideoDuration: (json['input_video_duration'] as num?)?.toInt(),
      outputVideoDuration: (json['output_video_duration'] as num?)?.toInt(),
      videoCount: (json['video_count'] as num?)?.toInt(),
      sr: (json['sr'] as num?)?.toInt(),
      videoRatio: json['video_ratio'] as String?,
    );

Map<String, dynamic> _$WanXiangUsageToJson(WanXiangUsage instance) =>
    <String, dynamic>{
      'duration': instance.duration,
      'input_video_duration': instance.inputVideoDuration,
      'output_video_duration': instance.outputVideoDuration,
      'video_count': instance.videoCount,
      'sr': instance.sr,
      'video_ratio': instance.videoRatio,
    };
