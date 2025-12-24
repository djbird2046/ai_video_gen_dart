import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

/// Supported Sora model names.
class SoraModelNames {
  SoraModelNames._();

  static const String sora2 = 'sora-2';
  static const String sora2Pro = 'sora-2-pro';
}

/// Sora task status values.
class SoraStatusValues {
  SoraStatusValues._();

  static const String queued = 'queued';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

/// Supported Sora content variants for downloads.
class SoraContentVariants {
  SoraContentVariants._();

  static const String video = 'video';
  static const String thumbnail = 'thumbnail';
  static const String spritesheet = 'spritesheet';
}

/// Common Sora size presets (width x height).
class SoraSizes {
  SoraSizes._();

  static const String p480 = '854x480';
  static const String p720 = '1280x720';
  static const String p1080 = '1920x1080';
  static const String k4 = '3840x2160';
}

/// Common Sora aspect ratios.
class SoraAspectRatios {
  SoraAspectRatios._();

  static const String landscape16x9 = '16:9';
  static const String portrait9x16 = '9:16';
  static const String square = '1:1';
  static const String landscape4x3 = '4:3';
  static const String portrait3x4 = '3:4';
}

/// Common Sora resolution presets (width x height).
class SoraResolutions {
  SoraResolutions._();

  static const String p480 = SoraSizes.p480;
  static const String p720 = SoraSizes.p720;
  static const String p1080 = SoraSizes.p1080;
  static const String k4 = SoraSizes.k4;
}

/// Common Sora durations in seconds.
class SoraDurations {
  SoraDurations._();

  static const int fiveSeconds = 5;
  static const int sixSeconds = 6;
  static const int eightSeconds = 8;
  static const int tenSeconds = 10;
}

/// JSON payload for creating a Sora video.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SoraCreateRequest {
  SoraCreateRequest({
    required this.prompt,
    this.model,
    this.size,
    this.seconds,
  });

  factory SoraCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$SoraCreateRequestFromJson(json);

  final String prompt;
  final String? model;
  final String? size;
  final int? seconds;

  Map<String, dynamic> toJson() => _$SoraCreateRequestToJson(this);
}

/// JSON payload for remixing a Sora video.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SoraRemixRequest {
  SoraRemixRequest({required this.prompt});

  factory SoraRemixRequest.fromJson(Map<String, dynamic> json) =>
      _$SoraRemixRequestFromJson(json);

  final String prompt;

  Map<String, dynamic> toJson() => _$SoraRemixRequestToJson(this);
}

/// Sora video job response.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SoraVideoResponse {
  SoraVideoResponse({
    this.id,
    this.object,
    this.createdAt,
    this.status,
    this.model,
    this.progress,
    this.seconds,
    this.size,
    this.error,
  });

  factory SoraVideoResponse.fromJson(Map<String, dynamic> json) =>
      _$SoraVideoResponseFromJson(json);

  final String? id;
  final String? object;
  @JsonKey(fromJson: _asInt)
  final int? createdAt;
  final String? status;
  final String? model;
  @JsonKey(fromJson: _asDouble)
  final double? progress;
  @JsonKey(fromJson: _asInt)
  final int? seconds;
  final String? size;
  final Object? error;

  Map<String, dynamic> toJson() => _$SoraVideoResponseToJson(this);
}

/// List response for Sora videos.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SoraListResponse {
  SoraListResponse({
    required this.data,
    this.object,
    this.firstId,
    this.lastId,
    this.hasMore,
  });

  factory SoraListResponse.fromJson(Map<String, dynamic> json) =>
      _$SoraListResponseFromJson(json);

  @JsonKey(defaultValue: <SoraVideoResponse>[])
  final List<SoraVideoResponse> data;
  final String? object;
  final String? firstId;
  final String? lastId;
  final bool? hasMore;

  Map<String, dynamic> toJson() => _$SoraListResponseToJson(this);
}

/// Delete response for a Sora video.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SoraDeleteResponse {
  SoraDeleteResponse({this.id, this.object, this.deleted});

  factory SoraDeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$SoraDeleteResponseFromJson(json);

  final String? id;
  final String? object;
  final bool? deleted;

  Map<String, dynamic> toJson() => _$SoraDeleteResponseToJson(this);
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
