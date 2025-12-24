## 0.1.0

- Initial public release.
- Supports OpenAI Sora 2, Google Vertex Veo (predictLongRunning + fetchPredictOperation), ByteDance JiMeng 3.0, Kwai Kling, and Alibaba WanXiang generators.
- Includes polling helper (`VideoGenerationClient`), proxy-aware HTTP defaults, and runnable examples for each provider.
- Adds `promptGuideUrl` and `capabilities` to `VideoGenerator`, plus per-provider prompt guide links and capabilities metadata.
- Improves download naming, request ID disambiguation, and permission fallback.
