import 'dart:io';
import 'dart:typed_data';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('polling continues on transient status errors', () async {
    final generator = _StubGenerator();
    final client = VideoGenerationClient(
      options: ClientOptions(pollIntervalMs: 1, maxPollTimeMs: 200),
    );

    final result = await client.generate(
      generator,
      UnifiedVideoRequest(prompt: 'hello'),
      onProgress: (_) {},
    );

    expect(result.status, GenerationStatus.succeeded);
    expect(generator.statusCalls, 2);
  });

  test('downloads content when videoUrl is missing', () async {
    final generator = _DownloadStubGenerator();
    final tempDir = Directory('test/.tmp_downloads');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final client = VideoGenerationClient(
      options: ClientOptions(
        pollIntervalMs: 1,
        maxPollTimeMs: 200,
        downloadDir: tempDir.path,
      ),
    );

    final result = await client.generate(
      generator,
      UnifiedVideoRequest(prompt: 'hello'),
      onProgress: (_) {},
    );

    expect(result.localFilePath, isNotNull);
    expect(File(result.localFilePath!).existsSync(), isTrue);
  });

  test('sanitizes filenames derived from provider names', () async {
    final generator = _WeirdNameGenerator();
    final tempDir = Directory('test/.tmp_downloads_safe');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final client = VideoGenerationClient(
      options: ClientOptions(
        pollIntervalMs: 1,
        maxPollTimeMs: 200,
        downloadDir: tempDir.path,
      ),
    );

    final result = await client.generate(
      generator,
      UnifiedVideoRequest(prompt: 'hello'),
      onProgress: (_) {},
    );

    final localPath = result.localFilePath;
    expect(localPath, isNotNull);
    final normalized = localPath!.replaceAll('\\', '/');
    final baseName = normalized.split('/').last;
    expect(baseName, startsWith('Weird-Name-Test_'));
    expect(baseName.contains(':'), isFalse);
    expect(baseName.contains('?'), isFalse);
    expect(baseName.endsWith('.mp4'), isTrue);
  });
}

class _StubGenerator implements VideoGenerator {
  int statusCalls = 0;

  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    return GenerationResult(
      requestId: 'job-1',
      status: GenerationStatus.queued,
    );
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    statusCalls += 1;
    if (statusCalls == 1) {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      throw VideoGenException(
        'Request POST /status failed: unknown null',
        cause: dioError,
      );
    }
    return GenerationResult(
      requestId: requestId,
      status: GenerationStatus.succeeded,
    );
  }

  @override
  String get providerName => 'Stub';

  @override
  String? get promptGuideUrl => null;

  @override
  GeneratorCapabilities? get capabilities => null;

  @override
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    return request;
  }
}

class _DownloadStubGenerator implements VideoGenerator, ContentDownloader {
  @override
  Future<GenerationResult> startGeneration(UnifiedVideoRequest request) async {
    return GenerationResult(
      requestId: 'job-2',
      status: GenerationStatus.succeeded,
    );
  }

  @override
  Future<GenerationResult> getStatus(
    String requestId, {
    String? apiKeyOverride,
  }) async {
    return GenerationResult(
      requestId: requestId,
      status: GenerationStatus.succeeded,
    );
  }

  @override
  String get providerName => 'Stub';

  @override
  String? get promptGuideUrl => null;

  @override
  GeneratorCapabilities? get capabilities => null;

  @override
  Future<UnifiedVideoRequest> preprocessRequest(
    UnifiedVideoRequest request,
  ) async {
    return request;
  }

  @override
  Future<Uint8List> downloadContent(
    String requestId, {
    String variant = 'video',
    String? apiKeyOverride,
  }) async {
    return Uint8List.fromList([0, 1, 2, 3]);
  }
}

class _WeirdNameGenerator extends _DownloadStubGenerator {
  @override
  String get providerName => 'Weird/Name:Test?';
}
