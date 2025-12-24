# AI Video Generation Dart SDK

面向 OpenAI Sora 2、Google Vertex Veo、字节跳动即梦、快手可灵、阿里巴巴通义万相的 Dart 视频生成客户端。每家都有独立的 generator，可直接调用，也可配合轻量的轮询工具类。默认域名内置，支持的厂商可自动把本地图片转为 Base64。

## 安装

```bash
dart pub add ai_video_gen_dart
```

运行示例前先准备环境变量（可复制 `.env.example` 到 `.env`）：

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
示例会通过 `example/env.dart` 自动读取根目录下的 `.env`，也可以在终端导出环境变量。

## 快速开始（OpenAI Sora 2）

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
      downloadDir: 'example/videos', // 自动下载生成视频
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

## API 概览
- `VideoGenerationClient` 是对任意 `VideoGenerator` 的轻量轮询封装。`ClientOptions` 仅配置轮询默认值（`pollIntervalMs` 默认 4000，`maxPollTimeMs` 默认 5 分钟）；也可直接调用 generator 的 `startGeneration`/`getStatus`。配置 `downloadDir` 可自动保存生成结果（若目录无权限创建，会回退到系统临时目录）。
- `client.generate` 支持可选的 `onProgress` 回调；传入后会像 `pollUntilDone` 一样自动轮询，并在每次状态变化时回调，同时返回最终的 `GenerationResult`。
- `UnifiedVideoRequest` 字段：必填 `prompt`，可选 `apiKey`、`model`、`durationSeconds`、`aspectRatio`、`resolution`、`seed`、`webhookUrl`、`metadata`（如参考图像）、`negativePrompt`、`guidanceScale`、`framesPerSecond`、`user`。分辨率、宽高比、时长建议使用对应厂商的 DTO 常量（如 `SoraSizes`、`JimengAspectRatios`、`WanXiangDurations`）避免手敲字符串。
- `pollUntilDone` 支持用 `PollOptions` 覆盖 `pollIntervalMs`、`maxPollTimeMs`，并可传独立的 `apiKey` 用于轮询。
- `GenerationResult` 包含 `requestId`、`status`（`queued|processing|streaming|succeeded|failed`）、可选的 `progress`（0–1）、`etaSeconds`、`videoUrl`、`coverUrl`、`errorMessage` 以及原始 `rawResponse`。
- `VideoGenerator.promptGuideUrl` 提供厂商官方提示词文档链接（可为空）。
- `VideoGenerator.capabilities` 提供可选的能力描述（如支持的宽高比/分辨率/时长），便于提前校验输入。

```dart
final guide = generator.promptGuideUrl;
if (guide != null) {
  print('Prompt guide: $guide');
}
```

## Providers
- 默认的 base URL 定义在各厂商生成器文件（`lib/src/providers/**`）；构造函数的 `baseUrl` 为可选字段，仅在需要自定义域名或地域时覆盖。支持 base64 的厂商会自动把本地图片路径转为 base64（见 `lib/src/utils/payload_utils.dart`）。
- 网络层使用 Dio；默认客户端会通过 `HttpClient.findProxyFromEnvironment` 读取 `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY`。如需自定义重试、代理规则或日志，可在各生成器构造函数里传入自定义 `Dio`（例如 `SoraGenerator(httpClient: dio)`）。
- OpenAI Sora 2：`https://api.openai.com/v1/videos`，使用 `SORA2_API_KEY` 的 Bearer 认证。`resolution` 会映射为 Sora 的 `size`（宽 x 高），`durationSeconds` 映射为 `seconds`。需要参考图时可在 `metadata['input_reference']` 传本地图片路径；下载 MP4/缩略图/精灵图请用 `SoraGenerator.downloadContent`。文档：[OpenAI Videos API](https://platform.openai.com/docs/api-reference/videos/create)。
- Google Vertex Veo（Vertex AI）：Bearer `VEO_OAUTH_TOKEN`，需要 `projectId`/`location`（构造函数参数），默认域名 `https://{location}-aiplatform.googleapis.com`。使用长任务接口：创建 `/v1/projects/{projectId}/locations/{location}/publishers/google/models/{model}:predictLongRunning`，查询 `/v1/projects/{projectId}/locations/{location}/publishers/google/models/{model}:fetchPredictOperation`。默认模型 `veo-3.1-generate-001`（可参考 `VeoModelIds`），Veo 3.x 需传 `generateAudio`，`resolution` 取 `720p`/`1080p`，时长 4/6/8 秒。文档：[Vertex AI Veo 视频生成](https://cloud.google.com/vertex-ai/generative-ai/docs/vision/video-generation)。
- 字节跳动即梦 3.0 Pro（火山）：域名 `https://visual.volcengineapi.com`，提交 `/?Action=CVSync2AsyncSubmitTask&Version=2022-08-31`，查询 `/?Action=CVSync2AsyncGetResult&Version=2022-08-31`，均为 POST，使用火山 SigV4（Region `cn-north-1`，Service `cv`）。`apiKey`=AK，`secretKey`=SK；也可把单次 `apiKey` 写成 `AK:SK`。负载字段来源于 `UnifiedVideoRequest` 与 `metadata`：`prompt`、`binary_data_base64`/`image_urls`、`seed`、`frames`、`aspect_ratio`、`req_key`（默认 `jimeng_ti2v_v30_pro`）。文档：火山引擎视觉开放平台（即梦 3.0 Pro）[API](https://www.volcengine.com/docs/82379/1374111)。
- 阿里巴巴通义万相（图生视频）：域名 `https://dashscope.aliyuncs.com`，创建 `/api/v1/services/aigc/video-generation/video-synthesis`（POST，需 `X-DashScope-Async: enable`），查询 `/api/v1/tasks/{task_id}`（GET）。Bearer `WANXIANG_API_KEY`。模型通过 `UnifiedVideoRequest.model` 或 `metadata['model']`（默认 `wan2.6-i2v`），必填首帧 `metadata['img_url']`/`metadata['image']`，可选 `audio_url`、`template`，以及 `parameters`：`resolution`、`duration`、`prompt_extend`、`shot_type`、`watermark`、`audio`、`seed`。文档：[DashScope 视频合成](https://help.aliyun.com/zh/dashscope/developer-reference/api-video-generation-video-synthesis)。
- 快手（Kwai）可灵（图生视频）：基础域名 `https://api-beijing.klingai.com`，创建 `/v1/videos/image2video`，查询 `/v1/videos/image2video/{task_id}`。必填参考图像放在 `UnifiedVideoRequest.metadata['image']`（URL 或 Base64），可选元数据：`image_tail`、`mode`、`cfg_scale`、`model_name`、`static_mask`、`dynamic_masks`、`camera_control`、`callback_url`、`external_task_id`。文档：[Kling API](https://app.klingai.com/cn/dev/document-api/apiReference/model/imageToVideo)。

## 示例
- `example/sora_example.dart`：OpenAI Sora 2 启动 + 轮询 + 下载流程。
- `example/jimeng3_pro_example.dart`：字节跳动即梦 3 Pro，自动把本地图片转为 Base64。
- `example/jimeng3_720p_example.dart`：字节跳动即梦 3 720p，自动把本地图片转为 Base64。
- `example/jimeng3_1080p_example.dart`：字节跳动即梦 3 1080p，自动把本地图片转为 Base64。
- `example/kling_example.dart`：快手（Kwai）可灵，自动把本地图片转为 Base64。
- `example/wanxiang_example.dart`：阿里巴巴通义万相，自动把本地图片转为 data:base64。
- `example/veo_example.dart`：Google Vertex Veo predictLongRunning + 轮询示例。

## 开发
- 规范命令：`dart format . && dart analyze && dart test`
- 基于 Dio 的 HTTP；如需重试、代理或日志，可通过各生成器构造函数注入自定义 `Dio` 实例。
