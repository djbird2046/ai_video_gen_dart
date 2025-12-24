import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

class JimengFrames {
  JimengFrames._();

  static const int fiveSeconds = 121; // 24 * 5 + 1
  static const int tenSeconds = 241; // 24 * 10 + 1
}

class JimengDurations {
  JimengDurations._();

  static const int fiveSeconds = 5;
  static const int tenSeconds = 10;
}

class JimengAspectRatios {
  JimengAspectRatios._();

  static const String landscape16x9 = '16:9';
  static const String landscape4x3 = '4:3';
  static const String square = '1:1';
  static const String portrait3x4 = '3:4';
  static const String portrait9x16 = '9:16';
  static const String ultraWide21x9 = '21:9';

  static const Map<String, List<int>> resolutions = {
    ultraWide21x9: [2176, 928],
    landscape16x9: [1920, 1088],
    landscape4x3: [1664, 1248],
    square: [1440, 1440],
    portrait3x4: [1248, 1664],
    portrait9x16: [1088, 1920],
  };
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class JimengSubmitRequest {
  JimengSubmitRequest({
    this.reqKey = 'jimeng_ti2v_v30_pro',
    required this.prompt,
    this.binaryDataBase64,
    this.imageUrls,
    this.seed,
    this.frames,
    this.aspectRatio,
  });

  final String reqKey;
  final String prompt;
  final List<String>? binaryDataBase64;
  final List<String>? imageUrls;
  final int? seed;
  final int? frames;
  final String? aspectRatio;

  factory JimengSubmitRequest.fromJson(Map<String, dynamic> json) =>
      _$JimengSubmitRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JimengSubmitRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class JimengStatusRequest {
  JimengStatusRequest({
    this.reqKey = 'jimeng_ti2v_v30_pro',
    required this.taskId,
  });

  final String reqKey;
  final String taskId;

  factory JimengStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$JimengStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JimengStatusRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class JimengResponse {
  JimengResponse({this.code, this.message, this.requestId, this.data});

  final int? code;
  final String? message;
  final String? requestId;
  final JimengTaskData? data;

  factory JimengResponse.fromJson(Map<String, dynamic> json) =>
      _$JimengResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JimengResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class JimengTaskData {
  JimengTaskData({this.taskId, this.status, this.videoUrl});

  final String? taskId;
  final String? status;
  final String? videoUrl;

  factory JimengTaskData.fromJson(Map<String, dynamic> json) =>
      _$JimengTaskDataFromJson(json);

  Map<String, dynamic> toJson() => _$JimengTaskDataToJson(this);
}
