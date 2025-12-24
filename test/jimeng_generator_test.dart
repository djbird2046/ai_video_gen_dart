import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('JiMeng maps progress from status response', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((request) async {
      return ResponseBody.fromString(
        '{"code":10000,"message":"OK","data":{"task_id":"task-1","status":"generating","progress":60}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final generator = JiMeng3P1080Generator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMeng3RequestOptions(image: 'unused'),
      httpClient: dio,
    );

    final result = await generator.getStatus('task-1');

    expect(result.status, GenerationStatus.processing);
    expect(result.progress, closeTo(0.6, 0.0001));
  });

  test('JiMeng defaults missing status to queued', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((request) async {
      return ResponseBody.fromString(
        '{"code":10000,"message":"OK","data":{"task_id":"task-1"}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final generator = JiMeng3P1080Generator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMeng3RequestOptions(image: 'unused'),
      httpClient: dio,
    );

    final result = await generator.getStatus('task-1');

    expect(result.status, GenerationStatus.queued);
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions request) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    return handler(options);
  }
}
