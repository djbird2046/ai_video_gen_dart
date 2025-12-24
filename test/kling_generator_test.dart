import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('KlingGenerator preprocessRequest', () {
    final generator = KlingGenerator(accessKey: 'token', secretKey: 'secret');

    test('requires image or image_tail', () async {
      final request = UnifiedVideoRequest(prompt: 'hello');
      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('rejects image_tail with masks', () async {
      final request = UnifiedVideoRequest(
        prompt: 'hello',
        metadata: {
          'image_tail': 'https://example.com/tail.png',
          'static_mask': 'https://example.com/mask.png',
        },
      );
      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('rejects too many dynamic_masks', () async {
      final masks = List.generate(
        7,
        (index) => {
          'mask': 'https://example.com/mask_$index.png',
          'trajectories': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 1},
          ],
        },
      );

      final request = UnifiedVideoRequest(
        prompt: 'hello',
        metadata: {
          'image': 'https://example.com/image.png',
          'dynamic_masks': masks,
        },
      );

      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('rejects unsupported duration', () async {
      final request = UnifiedVideoRequest(
        prompt: 'hello',
        durationSeconds: 6,
        metadata: {'image': 'https://example.com/image.png'},
      );

      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('validates camera_control simple config', () async {
      final request = UnifiedVideoRequest(
        prompt: 'hello',
        metadata: {
          'image': 'https://example.com/image.png',
          'camera_control': {
            'type': 'simple',
            'config': {'horizontal': 1, 'vertical': 1},
          },
        },
      );

      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });
  });

  test('KlingGenerator adds jwt bearer token', () async {
    final dio = Dio();
    late RequestOptions captured;
    dio.httpClientAdapter = _FakeAdapter((request) async {
      captured = request;
      return ResponseBody.fromString(
        '{"code":0,"data":{"task_id":"job-1","task_status":"submitted"}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final generator = KlingGenerator(
      accessKey: 'ak',
      secretKey: 'sk',
      httpClient: dio,
    );

    await generator.startGeneration(
      UnifiedVideoRequest(
        prompt: 'hello',
        metadata: {'image': 'https://example.com/image.png'},
      ),
    );

    final auth = captured.headers['Authorization'] as String?;
    expect(auth, isNotNull);
    expect(auth, startsWith('Bearer '));
    final token = auth!.substring('Bearer '.length);
    expect(token.split('.').length, 3);
  });

  test('KlingGenerator maps progress from status response', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((request) async {
      return ResponseBody.fromString(
        '{"code":0,"data":{"task_id":"job-1","task_status":"processing","progress":45}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final generator = KlingGenerator(
      accessKey: 'ak',
      secretKey: 'sk',
      httpClient: dio,
    );

    final result = await generator.getStatus('job-1');

    expect(result.status, GenerationStatus.processing);
    expect(result.progress, closeTo(0.45, 0.0001));
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
