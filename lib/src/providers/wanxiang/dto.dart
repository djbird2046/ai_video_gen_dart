import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

/// Supported WanXiang model names.
class WanXiangModelNames {
  WanXiangModelNames._();

  static const String wan2_6I2v = 'wan2.6-i2v';
  static const String wan2_5I2vPreview = 'wan2.5-i2v-preview';
  static const String wan2_2I2vFlash = 'wan2.2-i2v-flash';
  static const String wan2_2I2vPlus = 'wan2.2-i2v-plus';
  static const String wanx2_1I2vTurbo = 'wanx2.1-i2v-turbo';
  static const String wanx2_1I2vPlus = 'wanx2.1-i2v-plus';
}

/// Supported WanXiang resolution presets.
class WanXiangResolutions {
  WanXiangResolutions._();

  static const String p480 = '480P';
  static const String p720 = '720P';
  static const String p1080 = '1080P';
}

/// Model-specific resolution and duration constraints.
class WanXiangModelConstraints {
  WanXiangModelConstraints._();

  static const Map<String, List<String>> resolutionsByModel = {
    WanXiangModelNames.wan2_6I2v: [
      WanXiangResolutions.p720,
      WanXiangResolutions.p1080,
    ],
    WanXiangModelNames.wan2_5I2vPreview: [
      WanXiangResolutions.p480,
      WanXiangResolutions.p720,
      WanXiangResolutions.p1080,
    ],
    WanXiangModelNames.wan2_2I2vFlash: [
      WanXiangResolutions.p480,
      WanXiangResolutions.p720,
      WanXiangResolutions.p1080,
    ],
    WanXiangModelNames.wan2_2I2vPlus: [
      WanXiangResolutions.p480,
      WanXiangResolutions.p1080,
    ],
    WanXiangModelNames.wanx2_1I2vTurbo: [
      WanXiangResolutions.p480,
      WanXiangResolutions.p720,
    ],
    WanXiangModelNames.wanx2_1I2vPlus: [WanXiangResolutions.p720],
  };

  static const Map<String, String> defaultResolutionByModel = {
    WanXiangModelNames.wan2_6I2v: WanXiangResolutions.p1080,
    WanXiangModelNames.wan2_5I2vPreview: WanXiangResolutions.p1080,
    WanXiangModelNames.wan2_2I2vFlash: WanXiangResolutions.p720,
    WanXiangModelNames.wan2_2I2vPlus: WanXiangResolutions.p1080,
    WanXiangModelNames.wanx2_1I2vTurbo: WanXiangResolutions.p720,
    WanXiangModelNames.wanx2_1I2vPlus: WanXiangResolutions.p720,
  };

  static const Map<String, List<int>> durationsByModel = {
    WanXiangModelNames.wan2_6I2v: [5, 10, 15],
    WanXiangModelNames.wan2_5I2vPreview: [5, 10],
    WanXiangModelNames.wan2_2I2vPlus: [5],
    WanXiangModelNames.wan2_2I2vFlash: [5],
    WanXiangModelNames.wanx2_1I2vPlus: [5],
    WanXiangModelNames.wanx2_1I2vTurbo: [3, 4, 5],
  };

  static const Map<String, int> defaultDurationByModel = {
    WanXiangModelNames.wan2_6I2v: 5,
    WanXiangModelNames.wan2_5I2vPreview: 5,
    WanXiangModelNames.wan2_2I2vPlus: 5,
    WanXiangModelNames.wan2_2I2vFlash: 5,
    WanXiangModelNames.wanx2_1I2vPlus: 5,
    WanXiangModelNames.wanx2_1I2vTurbo: 5,
  };
}

/// Supported WanXiang duration values (seconds).
class WanXiangDurations {
  WanXiangDurations._();

  static const int fiveSeconds = 5;
  static const int tenSeconds = 10;
  static const int fifteenSeconds = 15;
}

/// Supported WanXiang shot types.
class WanXiangShotTypes {
  WanXiangShotTypes._();

  static const String single = 'single';
  static const String multi = 'multi';
}

/// WanXiang task status values.
class WanXiangTaskStatuses {
  WanXiangTaskStatuses._();

  static const String pending = 'PENDING';
  static const String running = 'RUNNING';
  static const String succeeded = 'SUCCEEDED';
  static const String failed = 'FAILED';
  static const String canceled = 'CANCELED';
  static const String unknown = 'UNKNOWN';
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class WanXiangCreateRequest {
  WanXiangCreateRequest({
    required this.model,
    required this.input,
    this.parameters,
  });

  factory WanXiangCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$WanXiangCreateRequestFromJson(json);

  final String model;
  final WanXiangInput input;
  final WanXiangParameters? parameters;

  Map<String, dynamic> toJson() => _$WanXiangCreateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class WanXiangInput {
  WanXiangInput({
    this.prompt,
    this.negativePrompt,
    required this.imgUrl,
    this.audioUrl,
    this.template,
  });

  factory WanXiangInput.fromJson(Map<String, dynamic> json) =>
      _$WanXiangInputFromJson(json);

  final String? prompt;
  final String? negativePrompt;
  final String imgUrl;
  final String? audioUrl;
  final String? template;

  Map<String, dynamic> toJson() => _$WanXiangInputToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class WanXiangParameters {
  WanXiangParameters({
    this.resolution,
    this.duration,
    this.promptExtend,
    this.shotType,
    this.audio,
    this.watermark,
    this.seed,
  });

  factory WanXiangParameters.fromJson(Map<String, dynamic> json) =>
      _$WanXiangParametersFromJson(json);

  final String? resolution;
  final int? duration;
  final bool? promptExtend;
  final String? shotType;
  final bool? audio;
  final bool? watermark;
  final int? seed;

  Map<String, dynamic> toJson() => _$WanXiangParametersToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WanXiangResponse {
  WanXiangResponse({
    this.output,
    this.requestId,
    this.code,
    this.message,
    this.usage,
  });

  factory WanXiangResponse.fromJson(Map<String, dynamic> json) =>
      _$WanXiangResponseFromJson(json);

  final WanXiangOutput? output;
  final String? requestId;
  final Object? code;
  final String? message;
  final WanXiangUsage? usage;

  Map<String, dynamic> toJson() => _$WanXiangResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WanXiangOutput {
  WanXiangOutput({
    this.taskId,
    this.taskStatus,
    this.submitTime,
    this.scheduledTime,
    this.endTime,
    this.origPrompt,
    this.actualPrompt,
    this.videoUrl,
  });

  factory WanXiangOutput.fromJson(Map<String, dynamic> json) =>
      _$WanXiangOutputFromJson(json);

  final String? taskId;
  final String? taskStatus;
  final String? submitTime;
  final String? scheduledTime;
  final String? endTime;
  final String? origPrompt;
  final String? actualPrompt;
  final String? videoUrl;

  Map<String, dynamic> toJson() => _$WanXiangOutputToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WanXiangUsage {
  WanXiangUsage({
    this.duration,
    this.inputVideoDuration,
    this.outputVideoDuration,
    this.videoCount,
    this.sr,
    this.videoRatio,
  });

  factory WanXiangUsage.fromJson(Map<String, dynamic> json) =>
      _$WanXiangUsageFromJson(json);

  final int? duration;
  final int? inputVideoDuration;
  final int? outputVideoDuration;
  final int? videoCount;
  final int? sr;
  final String? videoRatio;

  Map<String, dynamic> toJson() => _$WanXiangUsageToJson(this);
}
