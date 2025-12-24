// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoraCreateRequest _$SoraCreateRequestFromJson(Map<String, dynamic> json) =>
    SoraCreateRequest(
      prompt: json['prompt'] as String,
      model: json['model'] as String?,
      size: json['size'] as String?,
      seconds: (json['seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SoraCreateRequestToJson(SoraCreateRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'model': ?instance.model,
      'size': ?instance.size,
      'seconds': ?instance.seconds,
    };

SoraRemixRequest _$SoraRemixRequestFromJson(Map<String, dynamic> json) =>
    SoraRemixRequest(prompt: json['prompt'] as String);

Map<String, dynamic> _$SoraRemixRequestToJson(SoraRemixRequest instance) =>
    <String, dynamic>{'prompt': instance.prompt};

SoraVideoResponse _$SoraVideoResponseFromJson(Map<String, dynamic> json) =>
    SoraVideoResponse(
      id: json['id'] as String?,
      object: json['object'] as String?,
      createdAt: _asInt(json['created_at']),
      status: json['status'] as String?,
      model: json['model'] as String?,
      progress: _asDouble(json['progress']),
      seconds: _asInt(json['seconds']),
      size: json['size'] as String?,
      error: json['error'],
    );

Map<String, dynamic> _$SoraVideoResponseToJson(SoraVideoResponse instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'object': ?instance.object,
      'created_at': ?instance.createdAt,
      'status': ?instance.status,
      'model': ?instance.model,
      'progress': ?instance.progress,
      'seconds': ?instance.seconds,
      'size': ?instance.size,
      'error': ?instance.error,
    };

SoraListResponse _$SoraListResponseFromJson(Map<String, dynamic> json) =>
    SoraListResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (e) => SoraVideoResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      object: json['object'] as String?,
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool?,
    );

Map<String, dynamic> _$SoraListResponseToJson(SoraListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'object': ?instance.object,
      'first_id': ?instance.firstId,
      'last_id': ?instance.lastId,
      'has_more': ?instance.hasMore,
    };

SoraDeleteResponse _$SoraDeleteResponseFromJson(Map<String, dynamic> json) =>
    SoraDeleteResponse(
      id: json['id'] as String?,
      object: json['object'] as String?,
      deleted: json['deleted'] as bool?,
    );

Map<String, dynamic> _$SoraDeleteResponseToJson(SoraDeleteResponse instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'object': ?instance.object,
      'deleted': ?instance.deleted,
    };
