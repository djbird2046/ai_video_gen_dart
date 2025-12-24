import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'model.dart';
import 'base_generator.dart';
import 'utils/http_util.dart';

class VideoGenerationClient {
  VideoGenerationClient({ClientOptions? options})
    : options = options ?? const ClientOptions() {
    pollIntervalMs = this.options.pollIntervalMs ?? 4000;
    maxPollTimeMs = this.options.maxPollTimeMs ?? 5 * 60 * 1000;
    downloadDir = this.options.downloadDir;
  }

  final ClientOptions options;
  late final int pollIntervalMs;
  late final int? maxPollTimeMs;
  late final String? downloadDir;

  Future<GenerationResult> generate(
    VideoGenerator generator,
    UnifiedVideoRequest request, {
    PollOptions? pollOptions,
    void Function(GenerationResult result)? onProgress,
  }) async {
    final start = await generator.startGeneration(request);
    if (onProgress == null) {
      return start;
    }

    return _poll(
      generator,
      start.requestId,
      opts: pollOptions,
      initial: start,
      onProgress: onProgress,
    );
  }

  Future<GenerationResult> pollUntilDone(
    VideoGenerator generator,
    String requestId, {
    PollOptions? opts,
  }) async {
    return _poll(generator, requestId, opts: opts);
  }

  Future<GenerationResult> _poll(
    VideoGenerator generator,
    String requestId, {
    PollOptions? opts,
    GenerationResult? initial,
    void Function(GenerationResult result)? onProgress,
  }) async {
    final interval = opts?.pollIntervalMs ?? pollIntervalMs;
    final maxTime = opts?.maxPollTimeMs ?? maxPollTimeMs;
    final saveDir = opts?.downloadDir ?? downloadDir;
    final startedAt = DateTime.now().millisecondsSinceEpoch;

    GenerationResult last =
        initial ??
        await generator.getStatus(requestId, apiKeyOverride: opts?.apiKey);

    while (true) {
      onProgress?.call(last);
      if (last.status == GenerationStatus.succeeded ||
          last.status == GenerationStatus.failed) {
        break;
      }

      if (maxTime != null &&
          DateTime.now().millisecondsSinceEpoch - startedAt > maxTime) {
        throw VideoGenException(
          'Polling timed out after ${maxTime}ms ($requestId)',
        );
      }

      await Future<void>.delayed(Duration(milliseconds: interval));
      try {
        last = await generator.getStatus(
          requestId,
          apiKeyOverride: opts?.apiKey,
        );
      } on VideoGenException catch (error) {
        if (_isTransientPollError(error)) {
          continue;
        }
        rethrow;
      }
    }

    final withDownload = await _maybeDownload(
      last,
      saveDir,
      generator,
      onProgress,
      apiKeyOverride: opts?.apiKey,
    );
    if (withDownload != last) {
      onProgress?.call(withDownload);
    }
    return withDownload;
  }

  Future<GenerationResult> _maybeDownload(
    GenerationResult result,
    String? saveDir,
    VideoGenerator generator,
    void Function(GenerationResult result)? onProgress, {
    String? apiKeyOverride,
  }) async {
    if (result.status != GenerationStatus.succeeded || saveDir == null) {
      return result;
    }

    String? localPath;
    if (result.videoUrl != null) {
      localPath = await _downloadToDir(result, saveDir, generator, onProgress);
    } else if (generator is ContentDownloader) {
      final downloader = generator as ContentDownloader;
      final bytes = await downloader.downloadContent(
        result.requestId,
        apiKeyOverride: apiKeyOverride,
      );
      localPath = await _downloadBytesToDir(
        bytes,
        saveDir,
        generator,
        result.requestId,
      );
    } else {
      return result;
    }
    return GenerationResult(
      requestId: result.requestId,
      status: result.status,
      progress: result.progress,
      etaSeconds: result.etaSeconds,
      videoUrl: result.videoUrl,
      coverUrl: result.coverUrl,
      errorMessage: result.errorMessage,
      rawResponse: result.rawResponse,
      localFilePath: localPath,
    );
  }

  Future<String> _downloadToDir(
    GenerationResult result,
    String directoryPath,
    VideoGenerator generator,
    void Function(GenerationResult result)? onProgress,
  ) async {
    final uri = Uri.parse(result.videoUrl!);
    final dir = await _prepareDownloadDir(directoryPath);

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VideoGenException(
          'Failed to download video: HTTP ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final baseName =
          '${_providerLabel(generator)}_${_formatTimestamp(DateTime.now())}';
      final resolvedName = _ensureExtension(
        baseName,
        _inferExtension(uri, response.headers.contentType),
      );
      final filePath = '${dir.path}${Platform.pathSeparator}$resolvedName';
      final file = File(filePath);

      final totalBytes = response.contentLength;
      final hasTotal = totalBytes > 0;
      var lastProgress = -1.0;
      void reportProgress(double? progress) {
        if (onProgress == null) return;
        if (progress != null) {
          if (progress < 0) return;
          if (progress < lastProgress + 0.01 && progress != 1.0) return;
          lastProgress = progress;
        }
        onProgress(_downloadProgressResult(result, progress));
      }

      reportProgress(hasTotal ? 0.0 : null);

      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (hasTotal) {
            final progress = (received / totalBytes).clamp(0.0, 1.0);
            reportProgress(progress);
          }
        }
      } finally {
        await sink.close();
      }
      return file.path;
    } on VideoGenException {
      rethrow;
    } catch (error) {
      throw VideoGenException('Failed to download video: $error');
    } finally {
      client.close();
    }
  }
}

Future<String> _downloadBytesToDir(
  Uint8List bytes,
  String directoryPath,
  VideoGenerator generator,
  String requestId,
) async {
  final dir = await _prepareDownloadDir(directoryPath);

  final baseName =
      '${_providerLabel(generator)}_${_formatTimestamp(DateTime.now())}';
  final resolvedName = _ensureExtension(baseName, 'mp4');
  final filePath = '${dir.path}${Platform.pathSeparator}$resolvedName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return file.path;
}

final _invalidFileNameChars = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

String _sanitizeFileComponent(String value, {String fallback = 'VideoGen'}) {
  var sanitized = value.trim();
  if (sanitized.isEmpty) return fallback;
  sanitized = sanitized.replaceAll(_invalidFileNameChars, '-');
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), '-');
  sanitized = sanitized.replaceAll(RegExp(r'-+'), '-');
  sanitized = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');
  return sanitized.isEmpty ? fallback : sanitized;
}

Future<Directory> _prepareDownloadDir(String directoryPath) async {
  final dir = Directory(directoryPath);
  try {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  } on FileSystemException catch (error) {
    if (_isPermissionError(error)) {
      final fallback = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}ai_video_gen_dart',
      );
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }
    rethrow;
  }
}

String _ensureExtension(String baseName, String? extension) {
  final ext = extension?.trim();
  if (ext == null || ext.isEmpty) return '$baseName.mp4';
  final cleaned = ext.startsWith('.') ? ext.substring(1) : ext;
  return '$baseName.$cleaned';
}

String? _inferExtension(Uri uri, ContentType? contentType) {
  final fromQuery = _extensionFromMimeLike(uri.queryParameters['mime_type']);
  if (fromQuery != null) return fromQuery;
  final fromHeader = _extensionFromMimeLike(contentType?.mimeType);
  if (fromHeader != null) return fromHeader;
  final fromPath = _extensionFromPath(uri.pathSegments);
  if (fromPath != null) return fromPath;
  return null;
}

String? _extensionFromMimeLike(String? mimeLike) {
  if (mimeLike == null || mimeLike.isEmpty) return null;
  final normalized = mimeLike.toLowerCase();
  if (normalized.contains('mp4')) return 'mp4';
  if (normalized.contains('webm')) return 'webm';
  if (normalized.contains('x-matroska') || normalized.contains('mkv')) {
    return 'mkv';
  }
  if (normalized.contains('quicktime') || normalized.contains('mov')) {
    return 'mov';
  }
  if (normalized.contains('mpeg')) return 'mpg';
  if (normalized.contains('avi')) return 'avi';
  return null;
}

String? _extensionFromPath(List<String> segments) {
  for (final segment in segments.reversed) {
    if (segment.isEmpty || !segment.contains('.')) continue;
    final ext = segment.substring(segment.lastIndexOf('.') + 1);
    if (ext.isNotEmpty) return ext;
  }
  return null;
}

String _providerLabel(VideoGenerator generator) {
  final label = generator.providerName.trim();
  return _sanitizeFileComponent(label);
}

String _formatTimestamp(DateTime time) {
  String pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
  final date =
      '${time.year.toString().padLeft(4, '0')}-${pad(time.month)}-${pad(time.day)}';
  final clock = '${pad(time.hour)}${pad(time.minute)}${pad(time.second)}';
  return '${date}_$clock';
}

GenerationResult _downloadProgressResult(
  GenerationResult base,
  double? progress,
) {
  return GenerationResult(
    requestId: base.requestId,
    status: GenerationStatus.streaming,
    progress: progress,
    etaSeconds: base.etaSeconds,
    videoUrl: base.videoUrl,
    coverUrl: base.coverUrl,
    errorMessage: base.errorMessage,
    rawResponse: base.rawResponse,
    localFilePath: base.localFilePath,
  );
}

bool _isTransientPollError(VideoGenException error) {
  final cause = error.cause;
  if (cause is DioException) {
    return cause.response == null;
  }
  final message = error.message.toLowerCase();
  if (message.contains('failed: unknown')) return true;
  return message.contains('failed: null');
}

bool _isPermissionError(FileSystemException error) {
  final code = error.osError?.errorCode;
  if (code == 1 || code == 5 || code == 13) return true;
  final message = error.osError?.message.toLowerCase() ?? '';
  return message.contains('permission') ||
      message.contains('not permitted') ||
      message.contains('access is denied') ||
      message.contains('access denied');
}
