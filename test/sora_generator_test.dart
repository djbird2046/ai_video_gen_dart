import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('maps unified request to Sora payload and response', () async {
    final dio = Dio();
    late RequestOptions captured;
    dio.httpClientAdapter = _FakeAdapter((request) async {
      captured = request;
      final body = jsonEncode({
        'id': 'video_123',
        'status': 'in_progress',
        'progress': 33,
        'seconds': '8',
        'size': '1280x720',
      });
      return ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final generator = SoraGenerator(apiKey: 'token-123', httpClient: dio);
    final result = await generator.startGeneration(
      UnifiedVideoRequest(
        prompt: 'A cinematic shot of a lighthouse',
        resolution: '720p',
        durationSeconds: 8,
      ),
    );

    final data = captured.data as Map;
    expect(data['prompt'], 'A cinematic shot of a lighthouse');
    expect(data['size'], '1280x720');
    expect(data['seconds'], 8);

    expect(result.status, GenerationStatus.processing);
    expect(result.progress, closeTo(0.33, 0.001));
  });

  test('includes proxy hint on connection errors', () async {
    final dio = Dio();
    dio.httpClientAdapter = _ThrowingAdapter((request) async {
      throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection reset by peer'),
        message: 'The connection errored: Connection reset by peer',
      );
    });

    final generator = SoraGenerator(
      apiKey: 'token-123',
      baseUrl: 'https://api.example.com',
      httpClient: dio,
    );

    await expectLater(
      () => generator.startGeneration(
        UnifiedVideoRequest(prompt: 'A cinematic shot of a lighthouse'),
      ),
      throwsA(
        isA<VideoGenException>()
            .having((e) => e.message, 'message', contains('failed: unknown'))
            .having((e) => e.message, 'message', contains('url:'))
            .having((e) => e.message, 'message', contains('HTTPS_PROXY'))
            .having(
              (e) => e.message,
              'message',
              contains('https://api.example.com/v1/videos'),
            ),
      ),
    );
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

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.handler);

  final Future<void> Function(RequestOptions request) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    await handler(options);
    throw StateError('unreachable');
  }
}
