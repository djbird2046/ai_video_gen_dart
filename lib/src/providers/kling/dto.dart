import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

/// Supported Kling model_name values.
class KlingModelNames {
  KlingModelNames._();

  static const String klingV1 = 'kling-v1';
  static const String klingV1_5 = 'kling-v1-5';
  static const String klingV1_6 = 'kling-v1-6';
  static const String klingV2Master = 'kling-v2-master';
  static const String klingV2_1 = 'kling-v2-1';
  static const String klingV2_1Master = 'kling-v2-1-master';
  static const String klingV2_5Turbo = 'kling-v2-5-turbo';
}

/// Supported Kling mode values.
class KlingModes {
  KlingModes._();

  static const String std = 'std';
  static const String pro = 'pro';
}

/// Supported Kling duration values (seconds).
class KlingDurations {
  KlingDurations._();

  static const int fiveSeconds = 5;
  static const int tenSeconds = 10;
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class KlingCreateRequest {
  KlingCreateRequest({
    required this.prompt,
    this.modelName,
    this.mode,
    this.duration,
    this.image,
    this.imageTail,
    this.negativePrompt,
    this.cfgScale,
    this.staticMask,
    this.dynamicMasks,
    this.cameraControl,
    this.callbackUrl,
    this.externalTaskId,
  });

  factory KlingCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$KlingCreateRequestFromJson(json);

  final String prompt;
  final String? modelName;
  final String? mode;
  final String? duration;
  final String? image;
  final String? imageTail;
  final String? negativePrompt;
  final double? cfgScale;
  final String? staticMask;
  final List<KlingDynamicMask>? dynamicMasks;
  final KlingCameraControl? cameraControl;
  final String? callbackUrl;
  final String? externalTaskId;

  Map<String, dynamic> toJson() => _$KlingCreateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class KlingDynamicMask {
  KlingDynamicMask({this.mask, this.trajectories});

  factory KlingDynamicMask.fromJson(Map<String, dynamic> json) =>
      _$KlingDynamicMaskFromJson(json);

  final String? mask;
  final List<KlingTrajectory>? trajectories;

  Map<String, dynamic> toJson() => _$KlingDynamicMaskToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class KlingTrajectory {
  KlingTrajectory({this.x, this.y});

  factory KlingTrajectory.fromJson(Map<String, dynamic> json) =>
      _$KlingTrajectoryFromJson(json);

  final int? x;
  final int? y;

  Map<String, dynamic> toJson() => _$KlingTrajectoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class KlingCameraControl {
  KlingCameraControl({this.type, this.config});

  factory KlingCameraControl.fromJson(Map<String, dynamic> json) =>
      _$KlingCameraControlFromJson(json);

  final String? type;
  final KlingCameraControlConfig? config;

  Map<String, dynamic> toJson() => _$KlingCameraControlToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class KlingCameraControlConfig {
  KlingCameraControlConfig({
    this.horizontal,
    this.vertical,
    this.pan,
    this.tilt,
    this.roll,
    this.zoom,
  });

  factory KlingCameraControlConfig.fromJson(Map<String, dynamic> json) =>
      _$KlingCameraControlConfigFromJson(json);

  final double? horizontal;
  final double? vertical;
  final double? pan;
  final double? tilt;
  final double? roll;
  final double? zoom;

  Map<String, dynamic> toJson() => _$KlingCameraControlConfigToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KlingResponse {
  KlingResponse({this.code, this.message, this.requestId, this.data});

  factory KlingResponse.fromJson(Map<String, dynamic> json) =>
      _$KlingResponseFromJson(json);

  final int? code;
  final String? message;
  final String? requestId;
  final KlingTaskData? data;

  Map<String, dynamic> toJson() => _$KlingResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KlingTaskData {
  KlingTaskData({
    this.taskId,
    this.taskStatus,
    this.taskStatusMsg,
    this.taskInfo,
    this.taskResult,
    this.createdAt,
    this.updatedAt,
  });

  factory KlingTaskData.fromJson(Map<String, dynamic> json) =>
      _$KlingTaskDataFromJson(json);

  final String? taskId;
  final String? taskStatus;
  final String? taskStatusMsg;
  final KlingTaskInfo? taskInfo;
  final KlingTaskResult? taskResult;
  final int? createdAt;
  final int? updatedAt;

  Map<String, dynamic> toJson() => _$KlingTaskDataToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KlingTaskInfo {
  KlingTaskInfo({this.externalTaskId});

  factory KlingTaskInfo.fromJson(Map<String, dynamic> json) =>
      _$KlingTaskInfoFromJson(json);

  final String? externalTaskId;

  Map<String, dynamic> toJson() => _$KlingTaskInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KlingTaskResult {
  KlingTaskResult({this.videos});

  factory KlingTaskResult.fromJson(Map<String, dynamic> json) =>
      _$KlingTaskResultFromJson(json);

  final List<KlingVideo>? videos;

  Map<String, dynamic> toJson() => _$KlingTaskResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KlingVideo {
  KlingVideo({this.id, this.url, this.duration});

  factory KlingVideo.fromJson(Map<String, dynamic> json) =>
      _$KlingVideoFromJson(json);

  final String? id;
  final String? url;
  final String? duration;

  Map<String, dynamic> toJson() => _$KlingVideoToJson(this);
}
