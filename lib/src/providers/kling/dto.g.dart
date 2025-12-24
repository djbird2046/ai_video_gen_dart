// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KlingCreateRequest _$KlingCreateRequestFromJson(Map<String, dynamic> json) =>
    KlingCreateRequest(
      prompt: json['prompt'] as String,
      modelName: json['model_name'] as String?,
      mode: json['mode'] as String?,
      duration: json['duration'] as String?,
      image: json['image'] as String?,
      imageTail: json['image_tail'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
      cfgScale: (json['cfg_scale'] as num?)?.toDouble(),
      staticMask: json['static_mask'] as String?,
      dynamicMasks: (json['dynamic_masks'] as List<dynamic>?)
          ?.map((e) => KlingDynamicMask.fromJson(e as Map<String, dynamic>))
          .toList(),
      cameraControl: json['camera_control'] == null
          ? null
          : KlingCameraControl.fromJson(
              json['camera_control'] as Map<String, dynamic>,
            ),
      callbackUrl: json['callback_url'] as String?,
      externalTaskId: json['external_task_id'] as String?,
    );

Map<String, dynamic> _$KlingCreateRequestToJson(KlingCreateRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'model_name': ?instance.modelName,
      'mode': ?instance.mode,
      'duration': ?instance.duration,
      'image': ?instance.image,
      'image_tail': ?instance.imageTail,
      'negative_prompt': ?instance.negativePrompt,
      'cfg_scale': ?instance.cfgScale,
      'static_mask': ?instance.staticMask,
      'dynamic_masks': ?instance.dynamicMasks,
      'camera_control': ?instance.cameraControl,
      'callback_url': ?instance.callbackUrl,
      'external_task_id': ?instance.externalTaskId,
    };

KlingDynamicMask _$KlingDynamicMaskFromJson(Map<String, dynamic> json) =>
    KlingDynamicMask(
      mask: json['mask'] as String?,
      trajectories: (json['trajectories'] as List<dynamic>?)
          ?.map((e) => KlingTrajectory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KlingDynamicMaskToJson(KlingDynamicMask instance) =>
    <String, dynamic>{
      'mask': ?instance.mask,
      'trajectories': ?instance.trajectories,
    };

KlingTrajectory _$KlingTrajectoryFromJson(Map<String, dynamic> json) =>
    KlingTrajectory(
      x: (json['x'] as num?)?.toInt(),
      y: (json['y'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KlingTrajectoryToJson(KlingTrajectory instance) =>
    <String, dynamic>{'x': ?instance.x, 'y': ?instance.y};

KlingCameraControl _$KlingCameraControlFromJson(Map<String, dynamic> json) =>
    KlingCameraControl(
      type: json['type'] as String?,
      config: json['config'] == null
          ? null
          : KlingCameraControlConfig.fromJson(
              json['config'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$KlingCameraControlToJson(KlingCameraControl instance) =>
    <String, dynamic>{'type': ?instance.type, 'config': ?instance.config};

KlingCameraControlConfig _$KlingCameraControlConfigFromJson(
  Map<String, dynamic> json,
) => KlingCameraControlConfig(
  horizontal: (json['horizontal'] as num?)?.toDouble(),
  vertical: (json['vertical'] as num?)?.toDouble(),
  pan: (json['pan'] as num?)?.toDouble(),
  tilt: (json['tilt'] as num?)?.toDouble(),
  roll: (json['roll'] as num?)?.toDouble(),
  zoom: (json['zoom'] as num?)?.toDouble(),
);

Map<String, dynamic> _$KlingCameraControlConfigToJson(
  KlingCameraControlConfig instance,
) => <String, dynamic>{
  'horizontal': ?instance.horizontal,
  'vertical': ?instance.vertical,
  'pan': ?instance.pan,
  'tilt': ?instance.tilt,
  'roll': ?instance.roll,
  'zoom': ?instance.zoom,
};

KlingResponse _$KlingResponseFromJson(Map<String, dynamic> json) =>
    KlingResponse(
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      requestId: json['request_id'] as String?,
      data: json['data'] == null
          ? null
          : KlingTaskData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KlingResponseToJson(KlingResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'request_id': instance.requestId,
      'data': instance.data,
    };

KlingTaskData _$KlingTaskDataFromJson(Map<String, dynamic> json) =>
    KlingTaskData(
      taskId: json['task_id'] as String?,
      taskStatus: json['task_status'] as String?,
      taskStatusMsg: json['task_status_msg'] as String?,
      taskInfo: json['task_info'] == null
          ? null
          : KlingTaskInfo.fromJson(json['task_info'] as Map<String, dynamic>),
      taskResult: json['task_result'] == null
          ? null
          : KlingTaskResult.fromJson(
              json['task_result'] as Map<String, dynamic>,
            ),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KlingTaskDataToJson(KlingTaskData instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'task_status_msg': instance.taskStatusMsg,
      'task_info': instance.taskInfo,
      'task_result': instance.taskResult,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

KlingTaskInfo _$KlingTaskInfoFromJson(Map<String, dynamic> json) =>
    KlingTaskInfo(externalTaskId: json['external_task_id'] as String?);

Map<String, dynamic> _$KlingTaskInfoToJson(KlingTaskInfo instance) =>
    <String, dynamic>{'external_task_id': instance.externalTaskId};

KlingTaskResult _$KlingTaskResultFromJson(Map<String, dynamic> json) =>
    KlingTaskResult(
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => KlingVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KlingTaskResultToJson(KlingTaskResult instance) =>
    <String, dynamic>{'videos': instance.videos};

KlingVideo _$KlingVideoFromJson(Map<String, dynamic> json) => KlingVideo(
  id: json['id'] as String?,
  url: json['url'] as String?,
  duration: json['duration'] as String?,
);

Map<String, dynamic> _$KlingVideoToJson(KlingVideo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'duration': instance.duration,
    };
