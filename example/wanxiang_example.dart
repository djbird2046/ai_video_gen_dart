import 'dart:io';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';

import 'env.dart';

/// 通义万相图生视频示例：本地图片可自动转 data:base64。
///
/// 环境变量：
/// - WANXIANG_API_KEY
/// - LOCAL_IMAGE_PATH (可选，默认 example/images/Lenna.png)
Future<void> main() async {
  final generator = WanXiangGenerator(apiKey: env('WANXIANG_API_KEY'));
  final client = VideoGenerationClient(
    options: ClientOptions(pollIntervalMs: 5000, downloadDir: 'example/videos'),
  );

  final imagePath =
      Platform.environment['LOCAL_IMAGE_PATH'] ?? 'example/images/Lenna.png';

  final result = await client.generate(
    generator,
    UnifiedVideoRequest(
      prompt:
          'Keep the same subject and scene as the first frame, single shot, subtle motion, no scene cuts.',
      negativePrompt: 'scene change, cut, multi-shot, new subject',
      model: WanXiangModelNames.wan2_6I2v,
      metadata: {
        // 本地路径会自动转 data:{mime};base64,{data}
        'img_url': imagePath,
        'resolution': WanXiangResolutions.p720,
        'duration': WanXiangDurations.fiveSeconds,
        'prompt_extend': true,
        'shot_type': WanXiangShotTypes.single,
        'audio': false,
        'watermark': false,
        // 'audio_url': 'https://example.com/audio.mp3',
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
