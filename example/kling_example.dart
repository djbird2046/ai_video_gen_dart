import 'dart:io';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';

import 'env.dart';

/// 快手 Kling 图生视频示例：本地图片自动转 Base64。
///
/// 环境变量：
/// - KELING_ACCESS_KEY
/// - KELING_SECRET_KEY
/// - LOCAL_IMAGE_PATH (可选，默认 example/images/Lenna.png)
Future<void> main() async {
  final generator = KlingGenerator(
    accessKey: env('KELING_ACCESS_KEY'),
    secretKey: env('KELING_SECRET_KEY'),
  );
  final client = VideoGenerationClient(
    options: ClientOptions(pollIntervalMs: 5000, downloadDir: 'example/videos'),
  );

  final imagePath = env(
    'LOCAL_IMAGE_PATH',
    defaultValue: 'example/images/Lenna.png',
  );

  final result = await client.generate(
    generator,
    UnifiedVideoRequest(
      prompt: 'Make the woman in the picture smile brightly.',
      durationSeconds: KlingDurations.fiveSeconds,
      metadata: {
        'image': imagePath,
        'model_name': KlingModelNames.klingV1,
        'mode': KlingModes.pro,
      },
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
