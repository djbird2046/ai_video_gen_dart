import 'dart:io';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'env.dart';

Future<void> main() async {
  final proxyUrl = env(
    'HTTPS_PROXY',
    altKeys: const ['HTTP_PROXY', 'https_proxy', 'http_proxy'],
  );
  final Dio? httpClient = _createDioWithProxy(proxyUrl);

  final baseUrl = env('SORA_BASE_URL', altKeys: const ['OPENAI_BASE_URL']);
  final generator = SoraGenerator(
    apiKey: env('SORA2_API_KEY'),
    baseUrl: baseUrl.isEmpty ? null : baseUrl,
    httpClient: httpClient,
  );
  final client = VideoGenerationClient(
    options: ClientOptions(pollIntervalMs: 5000, downloadDir: 'example/videos'),
  );

  final imagePath = env(
    'LOCAL_IMAGE_PATH',
    defaultValue: 'example/images/Lenna.png',
  );
  try {
    final result = await client.generate(
      generator,
      UnifiedVideoRequest(
        prompt: 'Make the woman in the picture smile brightly.',
        model: SoraModelNames.sora2,
        durationSeconds: SoraDurations.eightSeconds,
        metadata: {'input_reference': imagePath},
      ),
      onProgress: (status) =>
          stdout.writeln('Status: ${status.status} ${status.progress ?? ''}'),
    );

    stdout.writeln('Final Status: ${result.status}');
    stdout.writeln('Video URL: ${result.videoUrl}');
    if (result.localFilePath != null) {
      stdout.writeln('Saved to: ${result.localFilePath}');
    }
  } on VideoGenException catch (error) {
    stderr.writeln(error);
    final cause = error.cause;
    final showProxyHint =
        cause is DioException && isTransientNetworkError(cause);
    if (showProxyHint) {
      stderr.writeln(
        'Tip: if you are behind a proxy/firewall, try setting HTTPS_PROXY/HTTP_PROXY '
        'or SORA_BASE_URL/OPENAI_BASE_URL in your environment or .env file.',
      );
    }
    exitCode = 1;
  }
}

Dio? _createDioWithProxy(String proxyUrl) {
  final trimmed = proxyUrl.trim();
  if (trimmed.isEmpty) return null;

  final proxy = Uri.tryParse(trimmed);
  if (proxy == null || proxy.host.isEmpty) return null;

  final port = proxy.hasPort
      ? proxy.port
      : (proxy.scheme.toLowerCase() == 'https' ? 443 : 80);

  final dio = Dio();
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.findProxy = (_) => 'PROXY ${proxy.host}:$port';
      return client;
    };
  }
  return dio;
}
