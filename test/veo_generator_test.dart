import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('VeoGenerator', () {
    test('maps request to predictLongRunning', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.httpClientAdapter = _FakeAdapter((request) async {
        captured = request;
        final body = jsonEncode({
          'name':
              'projects/p/locations/us-central1/publishers/google/models/${VeoModelIds.veo31Generate001}/operations/op123',
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final generator = VeoGenerator(
        oauthToken: 'token-123',
        projectId: 'p',
        location: 'us-central1',
        model: VeoModelIds.veo31Generate001,
        httpClient: dio,
      );

      final result = await generator.startGeneration(
        UnifiedVideoRequest(
          prompt: 'Hello Veo',
          durationSeconds: VeoDurations.eightSeconds,
          aspectRatio: VeoAspectRatios.landscape16x9,
          metadata: {
            'generate_audio': true,
            'storage_uri': 'gs://bucket/output/',
          },
        ),
      );

      final data = captured.data as Map;
      expect(captured.uri.path, endsWith(':predictLongRunning'));
      expect((data['instances'] as List).first['prompt'], 'Hello Veo');
      expect(data['parameters']['durationSeconds'], VeoDurations.eightSeconds);
      expect(data['parameters']['generateAudio'], isTrue);
      expect(data['parameters']['storageUri'], 'gs://bucket/output/');

      expect(result.requestId, contains('operations/op123'));
      expect(result.status, GenerationStatus.processing);
    });

    test('maps fetchPredictOperation response', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.httpClientAdapter = _FakeAdapter((request) async {
        captured = request;
        final body = jsonEncode({
          'name':
              'projects/p/locations/us-central1/publishers/google/models/${VeoModelIds.veo31Generate001}/operations/op123',
          'done': true,
          'response': {
            'videos': [
              {
                'gcsUri': 'gs://bucket/output/video.mp4',
                'mimeType': 'video/mp4',
              },
            ],
          },
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final generator = VeoGenerator(
        oauthToken: 'token-123',
        projectId: 'p',
        location: 'us-central1',
        model: VeoModelIds.veo31Generate001,
        httpClient: dio,
      );

      final result = await generator.getStatus(
        'projects/p/locations/us-central1/publishers/google/models/${VeoModelIds.veo31Generate001}/operations/op123',
      );

      final data = captured.data as Map;
      expect(captured.uri.path, endsWith(':fetchPredictOperation'));
      expect(data['operationName'], contains('operations/op123'));
      expect(result.status, GenerationStatus.succeeded);
      expect(result.videoUrl, 'gs://bucket/output/video.mp4');
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
