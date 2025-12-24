import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeStatus', () {
    test('maps common provider states', () {
      expect(normalizeStatus('queued'), GenerationStatus.queued);
      expect(normalizeStatus('pending'), GenerationStatus.queued);
      expect(normalizeStatus('running'), GenerationStatus.processing);
      expect(normalizeStatus('in_progress'), GenerationStatus.processing);
      expect(normalizeStatus('streaming'), GenerationStatus.streaming);
      expect(normalizeStatus('success'), GenerationStatus.succeeded);
      expect(normalizeStatus('failed'), GenerationStatus.failed);
      expect(normalizeStatus('unexpected'), GenerationStatus.processing);
    });
  });

  group('normalizeResponse', () {
    test('normalizes typical payloads', () {
      final result = normalizeResponse({
        'id': 'abc123',
        'status': 'completed',
        'progress': 80,
        'video_url': 'https://example.com/video.mp4',
        'preview': 'https://example.com/thumb.jpg',
      });

      expect(result.requestId, 'abc123');
      expect(result.status, GenerationStatus.succeeded);
      expect(result.progress, closeTo(0.8, 0.001));
      expect(result.videoUrl, contains('video.mp4'));
      expect(result.coverUrl, contains('thumb.jpg'));
    });
  });

  group('HttpProviderAdapter', () {
    test('sends auth headers and maps responses', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.httpClientAdapter = _FakeAdapter((request) async {
        captured = request;
        final body = jsonEncode({
          'id': 'job-123',
          'status': 'completed',
          'video_url': 'https://example.com/video.mp4',
          'progress': 100,
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final adapter = HttpProviderAdapter(
        defaultBaseUrl: 'https://api.example.com',
        startPath: '/start',
        statusPath: (requestId) => '/status/$requestId',
        authHeader: (apiKey) => 'Bearer $apiKey',
        config: const ProviderConfig(
          apiKey: 'token-123',
          extraHeaders: {'X-Test': '1'},
        ),
        httpClient: dio,
      );

      final result = await adapter.startGeneration(
        UnifiedVideoRequest(prompt: 'hello world'),
      );

      expect(captured.headers['Authorization'], 'Bearer token-123');
      expect(captured.headers['X-Test'], '1');
      expect(captured.uri.path, '/start');
      expect(result.requestId, 'job-123');
      expect(result.status, GenerationStatus.succeeded);
      expect(result.videoUrl, 'https://example.com/video.mp4');
    });

    test('adds proxy hint on connection errors', () async {
      final dio = Dio();
      dio.httpClientAdapter = _ThrowingAdapter((request) async {
        throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
          error: const SocketException('Connection reset by peer'),
          message: 'The connection errored: Connection reset by peer',
        );
      });

      final adapter = HttpProviderAdapter(
        defaultBaseUrl: 'https://api.example.com',
        startPath: '/start',
        statusPath: (requestId) => '/status/$requestId',
        authHeader: (apiKey) => 'Bearer $apiKey',
        config: const ProviderConfig(apiKey: 'token-123'),
        httpClient: dio,
      );

      await expectLater(
        () => adapter.startGeneration(UnifiedVideoRequest(prompt: 'hi')),
        throwsA(
          isA<VideoGenException>()
              .having((e) => e.message, 'message', contains('failed: unknown'))
              .having((e) => e.message, 'message', contains('url:'))
              .having((e) => e.message, 'message', contains('HTTPS_PROXY'))
              .having((e) => e.message, 'message', contains('api.example.com')),
        ),
      );
    });
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
