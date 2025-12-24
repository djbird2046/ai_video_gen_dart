import 'dart:io';

import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'env.dart';

Future<void> main() async {
  final oauthToken = env('VEO_OAUTH_TOKEN');
  final projectId = env('VEO_PROJECT_ID');
  final location = env('VEO_LOCATION', defaultValue: 'us-central1');
  final model = env('VEO_MODEL', defaultValue: VeoModelIds.veo31Generate001);
  final baseUrl = env('VEO_BASE_URL');
  final storageUri = env('VEO_STORAGE_URI');

  if (oauthToken.isEmpty || projectId.isEmpty) {
    stderr.writeln(
      'Please set VEO_OAUTH_TOKEN and VEO_PROJECT_ID in environment or .env',
    );
    exitCode = 1;
    return;
  }

  final generator = VeoGenerator(
    oauthToken: oauthToken,
    projectId: projectId,
    location: location.isEmpty ? 'us-central1' : location,
    model: model.isEmpty ? VeoModelIds.veo31Generate001 : model,
    baseUrl: baseUrl.isEmpty ? null : baseUrl,
  );

  final client = VideoGenerationClient(
    options: const ClientOptions(pollIntervalMs: 6000),
  );

  try {
    final result = await client.generate(
      generator,
      UnifiedVideoRequest(
        prompt:
            'A cinematic aerial shot of a futuristic city at dusk, neon lights glowing.',
        durationSeconds: VeoDurations.eightSeconds,
        aspectRatio: VeoAspectRatios.landscape16x9,
        resolution: VeoResolutions.p1080,
        metadata: {
          'generate_audio': true, // Veo 3.x requires this field.
          'sample_count': 1,
          if (storageUri.isNotEmpty) 'storage_uri': storageUri,
        },
      ),
      onProgress: (status) =>
          stdout.writeln('Status: ${status.status} ${status.progress ?? ''}'),
    );

    stdout.writeln('Final Status: ${result.status}');
    stdout.writeln('Video URL (GCS or base64): ${result.videoUrl}');
  } on VideoGenException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
