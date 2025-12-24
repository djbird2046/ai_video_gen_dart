import 'package:ai_video_gen_dart/ai_video_gen_dart.dart';
import 'package:test/test.dart';

void main() {
  test('exposes capability metadata per provider', () {
    final jimeng3Pro = JiMeng3ProGenerator(
      accessKey: 'ak',
      secretAccessKey: 'sk',
      options: JiMengRequestOptions(image: 'image.png'),
    );
    expect(
      jimeng3Pro.capabilities?.aspectRatios,
      contains(JimengAspectRatios.landscape16x9),
    );
    expect(
      jimeng3Pro.capabilities?.durationsSeconds,
      contains(JimengDurations.fiveSeconds),
    );
    final jimengSizes = jimeng3Pro.capabilities?.sizesByAspectRatio;
    expect(jimengSizes?[JimengAspectRatios.landscape16x9], isNotNull);

    final sora = SoraGenerator(apiKey: 'sk');
    expect(sora.capabilities?.resolutions, contains(SoraResolutions.p1080));
    expect(
      sora.capabilities?.durationsSeconds,
      contains(SoraDurations.tenSeconds),
    );

    final veo = VeoGenerator(
      oauthToken: 'token',
      projectId: 'project-id',
      location: 'us-central1',
    );
    expect(veo.capabilities?.resolutions, contains(VeoResolutions.p720));

    final wanxiang = WanXiangGenerator(apiKey: 'sk');
    final wanxiangCaps = wanxiang.capabilities;
    expect(
      wanxiangCaps?.resolutionsByModel?[WanXiangModelNames.wan2_6I2v],
      contains(WanXiangResolutions.p1080),
    );
    expect(
      wanxiangCaps?.durationsByModel?[WanXiangModelNames.wan2_6I2v],
      contains(WanXiangDurations.fifteenSeconds),
    );

    final kling = KlingGenerator(accessKey: 'ak', secretKey: 'sk');
    expect(
      kling.capabilities?.durationsSeconds,
      contains(KlingDurations.tenSeconds),
    );
  });
}
