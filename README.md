# AI Video Generation Dart SDK

Typed, null-safe client for launching and monitoring video generation jobs across OpenAI Sora 2, Google Vertex Veo, ByteDance JiMeng, Kwai Kling, and Alibaba WanXiang. Each provider has its own generator class; you can use them directly or with the lightweight polling helper. Local image paths can auto-convert to base64 where supported.

## Installation

```bash
dart pub add ai_video_gen_dart
```

Copy `.env.example` to `.env` (or export these vars) before running the examples:

```
SORA2_API_KEY=sk-...
SORA_BASE_URL=https://api.openai.com
VEO_OAUTH_TOKEN=ya29....
VEO_LOCATION=us-central1
VEO_PROJECT_ID=your-project-id
VEO_MODEL=veo-3.1-generate-001
VEO_BASE_URL=
VEO_STORAGE_URI=gs://your-bucket/prefix/
JIMENG_ACCESS_KEY=AK...
JIMENG_SECRET_ACCESS_KEY=SK...
WANXIANG_API_KEY=sk-...
KELING_ACCESS_KEY=AKID...
KELING_SECRET_KEY=SECRET
LOCAL_IMAGE_PATH=example/images/Lenna.png
```
The examples load these automatically from `.env` via `example/env.dart`, or you can export them in your shell.

## Quickstart (OpenAI Sora 2)

```dart
import 'dart:io';
import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';

Future<void> main() async {
  final generator = SoraGenerator(
    apiKey: Platform.environment['SORA2_API_KEY'] ?? '',
  );

  final client = VideoGenerationClient(
    options: ClientOptions(
      pollIntervalMs: 5000,
      downloadDir: 'example/videos', // auto-save outputs
    ),
  );

  final job = await client.generate(
    generator,
    UnifiedVideoRequest(
      prompt: 'A slow drone shot over a neon city in the rain',
      durationSeconds: SoraDurations.eightSeconds,
      resolution: SoraSizes.p1080,
      aspectRatio: SoraAspectRatios.landscape16x9,
    ),
    onProgress: (status) =>
        stdout.writeln('Status: ${status.status} ${status.progress ?? ''}'),
  );

  print(
    '${job.status} ${job.progress} ${job.videoUrl} local=${job.localFilePath}',
  );
}
```

## API Overview
- `VideoGenerationClient` is a light polling helper around any `VideoGenerator`. Configure polling defaults with `ClientOptions` (`pollIntervalMs` defaults to 4000, `maxPollTimeMs` defaults to 5 minutes), or call generator methods directly. Set `downloadDir` to auto-save results (falls back to a system temp folder if creation is not permitted).
- `client.generate` accepts an optional `onProgress` callback; when provided it will poll like `pollUntilDone`, pushing each status update via the callback and returning the final `GenerationResult`.
- `UnifiedVideoRequest` fields: `prompt` (required) plus optional `apiKey`, `model`, `durationSeconds`, `aspectRatio`, `resolution`, `seed`, `webhookUrl`, `metadata` (e.g., reference images), `negativePrompt`, `guidanceScale`, `framesPerSecond`, `user`. Use provider-specific DTO constants (e.g., `SoraSizes`, `JimengAspectRatios`, `WanXiangDurations`) to avoid typos.
- `pollUntilDone` accepts `PollOptions` to override `pollIntervalMs` or `maxPollTimeMs`, and to supply a different `apiKey` for polling if needed.
- `GenerationResult` exposes `requestId`, `status` (`queued|processing|streaming|succeeded|failed`), optional `progress` (0–1), `etaSeconds`, `videoUrl`, `coverUrl`, `errorMessage`, and the original `rawResponse`.
- `VideoGenerator.promptGuideUrl` is an optional official prompt guide link for the provider.
- `VideoGenerator.capabilities` exposes optional supported values (aspect ratios/resolutions/durations) to help pre-validate user input.

```dart
final guide = generator.promptGuideUrl;
if (guide != null) {
  print('Prompt guide: $guide');
}
```

## Providers
- Default endpoints live in each provider generator (`lib/src/providers/**`); constructor `baseUrl` is optional—override only when you need a custom endpoint/region. Local file paths for images are automatically converted to base64 where the provider accepts it (see `lib/src/utils/payload_utils.dart`).
- Networking uses Dio; the default client honors `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY` via `HttpClient.findProxyFromEnvironment`. If you need custom logging/retries/proxy rules, pass a configured `Dio` to the generator constructor (e.g. `SoraGenerator(httpClient: dio)`).
- OpenAI Sora 2: `https://api.openai.com/v1/videos` with bearer `SORA2_API_KEY`. `resolution` maps to the Sora `size` field (width x height) and `durationSeconds` maps to `seconds`. For image references, set `metadata['input_reference']` to a local file path. Use `SoraGenerator.downloadContent` to fetch MP4/thumbnail/spritesheet variants. Docs: [OpenAI Videos API](https://platform.openai.com/docs/api-reference/videos/create).
- Google Vertex Veo (Vertex AI): bearer `VEO_OAUTH_TOKEN` plus `projectId`/`location` (constructor params); base URL defaults to `https://{location}-aiplatform.googleapis.com`. Uses long-running endpoints: start `/v1/projects/{projectId}/locations/{location}/publishers/google/models/{model}:predictLongRunning` and poll `/v1/projects/{projectId}/locations/{location}/publishers/google/models/{model}:fetchPredictOperation`. Default model is `veo-3.1-generate-001` (see `VeoModelIds` for options). Veo 3.x requires `generateAudio`; `resolution` accepts `720p`/`1080p`; durations 4/6/8s. Docs: [Vertex AI Veo video generation](https://cloud.google.com/vertex-ai/generative-ai/docs/vision/video-generation).
- ByteDance JiMeng 3.0 Pro (Volcengine): base `https://visual.volcengineapi.com`, submit `/?Action=CVSync2AsyncSubmitTask&Version=2022-08-31`, poll `/?Action=CVSync2AsyncGetResult&Version=2022-08-31`, method POST with Volcengine SigV4 (Region `cn-north-1`, Service `cv`). Set `apiKey` = access key and `secretKey` = secret key; per-call override can be `apiKey` as `AK:SK`. Payload fields come from `UnifiedVideoRequest` + `metadata`: `prompt`, `binary_data_base64`/`image_urls`, `seed`, `frames`, `aspect_ratio`, `req_key` (default `jimeng_ti2v_v30_pro`). Docs: Volcengine Visual (即梦 3.0 Pro) [API](https://www.volcengine.com/docs/82379/1374111).
- Alibaba WanXiang (Image-to-Video): base `https://dashscope.aliyuncs.com`, start `/api/v1/services/aigc/video-generation/video-synthesis` (POST with `X-DashScope-Async: enable`), status `/api/v1/tasks/{task_id}` (GET). Bearer `WANXIANG_API_KEY`. Model via `request.model` or `metadata['model']` (default `wan2.6-i2v`), required `img_url` in `metadata['img_url']`/`metadata['image']`, optional `audio_url`, `template`, and `parameters` (resolution, duration, prompt_extend, shot_type, watermark, audio, seed). Docs: [DashScope Video Synthesis](https://help.aliyun.com/zh/dashscope/developer-reference/api-video-generation-video-synthesis).
- Kwai Kling (可灵图生视频): base URL `https://api-beijing.klingai.com`, start `/v1/videos/image2video`, status `/v1/videos/image2video/{task_id}`. Send required image via `metadata['image']` (URL or base64) and optional fields `image_tail`, `mode`, `cfg_scale`, `model_name`, `static_mask`, `dynamic_masks`, `camera_control`, `callback_url`, `external_task_id`. Docs: [Kling API](https://app.klingai.com/cn/dev/document-api/apiReference/model/imageToVideo).

## Examples
- `example/sora_example.dart` — OpenAI Sora 2 start + poll + download flow.
- `example/jimeng3_pro_example.dart` — ByteDance JiMeng 3 Pro, auto-convert local images to Base64.
- `example/jimeng3_720p_example.dart` — ByteDance JiMeng 3 720p, auto-convert local images to Base64.
- `example/jimeng3_1080p_example.dart` — ByteDance JiMeng 3 1080p, auto-convert local images to Base64.
- `example/kling_example.dart` — Kwai Kling, auto-convert local images to Base64.
- `example/wanxiang_example.dart` — Alibaba WanXiang, auto-convert local images to data:base64.
- `example/veo_example.dart` — Google Vertex Veo predictLongRunning + poll flow.

## Development
- Lint/format/test: `dart format . && dart analyze && dart test`
- HTTP uses Dio; supply a custom `Dio` via each generator constructor if you need retries, proxies, or logging.
