import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('WanXiangGenerator', () {
    test('maps request payload with new parameters', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.httpClientAdapter = _FakeAdapter((request) async {
        captured = request;
        final body = jsonEncode({
          'output': {'task_id': 'task-1', 'task_status': 'PENDING'},
          'request_id': 'req-1',
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final generator = WanXiangGenerator(apiKey: 'token-123', httpClient: dio);

      final result = await generator.startGeneration(
        UnifiedVideoRequest(
          prompt: 'city rap scene',
          metadata: {
            'img_url': 'https://example.com/first.png',
            'resolution': WanXiangResolutions.p720,
            'duration': 10,
            'prompt_extend': true,
            'shot_type': WanXiangShotTypes.multi,
            'audio': false,
          },
        ),
      );

      final data =
          jsonDecode(jsonEncode(captured.data)) as Map<String, dynamic>;
      expect(data['model'], WanXiangModelNames.wan2_6I2v);
      expect(data['input'], isA<Map>());
      final input = data['input'] as Map<String, dynamic>;
      expect(input['img_url'], 'https://example.com/first.png');
      final parameters = data['parameters'] as Map<String, dynamic>;
      expect(parameters['resolution'], '720P');
      expect(parameters['duration'], 10);
      expect(parameters['shot_type'], 'multi');
      expect(parameters['audio'], false);
      expect(result.requestId, 'task-1');
      expect(result.status, GenerationStatus.queued);
    });

    test('drops audio when audio_url is provided', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.httpClientAdapter = _FakeAdapter((request) async {
        captured = request;
        final body = jsonEncode({
          'output': {'task_id': 'task-2', 'task_status': 'PENDING'},
          'request_id': 'req-2',
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final generator = WanXiangGenerator(apiKey: 'token-123', httpClient: dio);

      await generator.startGeneration(
        UnifiedVideoRequest(
          prompt: 'city rap scene',
          metadata: {
            'img_url': 'https://example.com/first.png',
            'audio_url': 'https://example.com/audio.mp3',
            'audio': true,
          },
        ),
      );

      final data =
          jsonDecode(jsonEncode(captured.data)) as Map<String, dynamic>;
      final input = data['input'] as Map<String, dynamic>;
      expect(input['audio_url'], 'https://example.com/audio.mp3');
      final parameters = data['parameters'] as Map<String, dynamic>?;
      expect(parameters == null || !parameters.containsKey('audio'), isTrue);
    });

    test('requires img_url or image metadata', () async {
      final generator = WanXiangGenerator(apiKey: 'token-123');

      expect(
        () => generator.startGeneration(
          UnifiedVideoRequest(prompt: 'missing image'),
        ),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('rejects unsupported resolution for model', () async {
      final generator = WanXiangGenerator(apiKey: 'token-123');
      final request = UnifiedVideoRequest(
        prompt: 'hello',
        model: WanXiangModelNames.wan2_6I2v,
        metadata: {
          'img_url': 'https://example.com/first.png',
          'resolution': WanXiangResolutions.p480,
        },
      );

      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
      );
    });

    test('rejects unsupported duration for model', () async {
      final generator = WanXiangGenerator(apiKey: 'token-123');
      final request = UnifiedVideoRequest(
        prompt: 'hello',
        model: WanXiangModelNames.wan2_5I2vPreview,
        metadata: {'img_url': 'https://example.com/first.png', 'duration': 15},
      );

      await expectLater(
        generator.preprocessRequest(request),
        throwsA(isA<VideoGenException>()),
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
