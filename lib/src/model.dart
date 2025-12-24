/// Common status values returned by video generation providers.
enum GenerationStatus {
  /// Job is queued and waiting for processing.
  queued,

  /// Job is actively being processed.
  processing,

  /// Job is streaming partial output (provider-specific).
  streaming,

  /// Job completed successfully.
  succeeded,

  /// Job failed or was canceled.
  failed,
}

class UnifiedVideoRequest {
  UnifiedVideoRequest({
    this.apiKey,
    required this.prompt,
    this.model,
    this.durationSeconds,
    this.aspectRatio,
    this.resolution,
    this.seed,
    this.webhookUrl,
    this.metadata,
    this.negativePrompt,
    this.guidanceScale,
    this.framesPerSecond,
    this.user,
  });

  final String? apiKey;
  final String prompt;
  final String? model;
  final int? durationSeconds;

  /// Provider-specific aspect ratio string, if supported.
  final String? aspectRatio;

  /// Provider-specific resolution string, if supported.
  final String? resolution;
  final int? seed;
  final String? webhookUrl;
  final Map<String, Object?>? metadata;
  final String? negativePrompt;
  final double? guidanceScale;
  final int? framesPerSecond;
  final String? user;
}

class GenerationResult {
  GenerationResult({
    required this.requestId,
    required this.status,
    this.progress,
    this.etaSeconds,
    this.videoUrl,
    this.coverUrl,
    this.errorMessage,
    this.rawResponse,
    this.localFilePath,
  });

  final String requestId;
  final GenerationStatus status;
  final double? progress;
  final int? etaSeconds;
  final String? videoUrl;
  final String? coverUrl;
  final String? errorMessage;
  final Object? rawResponse;
  final String? localFilePath;
}

/// Optional capabilities metadata for a generator.
class GeneratorCapabilities {
  const GeneratorCapabilities({
    this.aspectRatios,
    this.resolutions,
    this.durationsSeconds,
    this.resolutionsByModel,
    this.durationsByModel,
    this.sizesByAspectRatio,
  });

  /// Supported aspect ratios (e.g. `16:9`).
  final List<String>? aspectRatios;

  /// Supported resolution presets (e.g. `720p` or `1920x1080`).
  final List<String>? resolutions;

  /// Supported durations in seconds.
  final List<int>? durationsSeconds;

  /// Supported resolutions keyed by model name.
  final Map<String, List<String>>? resolutionsByModel;

  /// Supported durations keyed by model name (seconds).
  final Map<String, List<int>>? durationsByModel;

  /// Pixel size per aspect ratio as `[width, height]`.
  final Map<String, List<int>>? sizesByAspectRatio;
}

class ProviderConfig {
  const ProviderConfig({
    this.apiKey,
    this.baseUrl,
    this.extraHeaders,
    this.model,
    this.secretKey,
  });

  final String? apiKey;
  final String? baseUrl;
  final Map<String, String>? extraHeaders;
  final String? model;
  final String? secretKey;
}

class ClientOptions {
  const ClientOptions({
    this.pollIntervalMs,
    this.maxPollTimeMs,
    this.downloadDir,
  });

  final int? pollIntervalMs;
  final int? maxPollTimeMs;

  /// Directory to save downloaded media outputs.
  /// Falls back to a system temp folder if creation is not permitted.
  final String? downloadDir;
}

class PollOptions {
  const PollOptions({
    this.pollIntervalMs,
    this.maxPollTimeMs,
    this.apiKey,
    this.downloadDir,
  });

  final int? pollIntervalMs;
  final int? maxPollTimeMs;
  final String? apiKey;

  /// Directory to save downloaded media outputs.
  /// Falls back to a system temp folder if creation is not permitted.
  final String? downloadDir;
}
