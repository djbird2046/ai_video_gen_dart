import 'dart:io';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';

import 'env.dart';

/// - JIMENG_ACCESS_KEY
/// - JIMENG_SECRET_ACCESS_KEY
/// - LOCAL_IMAGE_PATH (option, default: example/images/Lenna.png)
Future<void> main() async {
  final generator = JiMeng3P1080Generator(
    accessKey: env('JIMENG_ACCESS_KEY'),
    secretAccessKey: env(
      'JIMENG_SECRET_ACCESS_KEY',
      altKeys: <String>['JIMENG_SECRET_ACCESSS_KEY'],
    ),
    options: JiMeng3RequestOptions(
      image: env('LOCAL_IMAGE_PATH', defaultValue: 'example/images/Lenna.png'),
    ),
  );
  final client = VideoGenerationClient(
    options: ClientOptions(pollIntervalMs: 5000, downloadDir: 'example/videos'),
  );

  final result = await client.generate(
    generator,
    UnifiedVideoRequest(
      prompt: 'Make the woman in the picture smile brightly.',
      durationSeconds: JimengDurations.fiveSeconds,
    ),
    onProgress: (status) =>
        stdout.writeln('Status: ${status.status} ${status.progress ?? ''}'),
  );

  stdout.writeln('Final Status: ${result.status}');
  stdout.writeln('Video URL: ${result.videoUrl}');
  if (result.localFilePath != null) {
    stdout.writeln('Saved to: ${result.localFilePath}');
  }
}
