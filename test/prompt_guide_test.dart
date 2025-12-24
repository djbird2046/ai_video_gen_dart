import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:test/test.dart';

void main() {
  test('exposes official prompt guide urls for providers', () {
    final jimeng3Pro = JiMeng3ProGenerator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMengRequestOptions(image: 'image.png'),
    );
    expect(
      jimeng3Pro.promptGuideUrl,
      'https://www.volcengine.com/docs/85621/1783678',
    );

    final jimeng3P1080 = JiMeng3P1080Generator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMeng3RequestOptions(image: 'image.png'),
    );
    expect(
      jimeng3P1080.promptGuideUrl,
      'https://www.volcengine.com/docs/85621/1792707',
    );

    final jimeng3P720 = JiMeng3P720Generator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMeng3RequestOptions(image: 'image.png'),
    );
    expect(
      jimeng3P720.promptGuideUrl,
      'https://www.volcengine.com/docs/85621/1792707',
    );

    final sora = SoraGenerator(apiKey: 'sk');
    expect(
      sora.promptGuideUrl,
      'https://cookbook.openai.com/examples/sora/sora2_prompting_guide',
    );

    final veo = VeoGenerator(
      oauthToken: 'token',
      projectId: 'project-id',
      location: 'us-central1',
    );
    expect(
      veo.promptGuideUrl,
      'https://docs.cloud.google.com/vertex-ai/generative-ai/docs/video/video-gen-prompt-guide',
    );

    final wanxiang = WanXiangGenerator(apiKey: 'sk');
    expect(
      wanxiang.promptGuideUrl,
      'https://bailian.console.aliyun.com/?tab=doc#/doc/?type=model&url=2865313',
    );

    final kling = KlingGenerator(accessKey: 'ak', secretKey: 'sk');
    expect(
      kling.promptGuideUrl,
      'https://docs.qingque.cn/d/home/eZQDKi7uTmtUr3iXnALzw6vxp?identityId=26L1FFNIZ7r#section=h.j6c40npi1fan',
    );
  });
}
