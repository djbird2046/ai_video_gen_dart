import 'jimeng_3_1080p_generator.dart';

const String _jimeng3ReqKey720p = 'jimeng_i2v_first_v30';

class JiMeng3P720Generator extends JiMeng3P1080Generator {
  JiMeng3P720Generator({
    required super.accessKey,
    required super.secretAccessKey,
    required super.options,
    super.baseUrl,
    super.httpClient,
    super.region = 'cn-north-1',
    super.service = 'cv',
  }) : super(reqKeyOverride: _jimeng3ReqKey720p);

  @override
  String get providerName => 'JiMeng3_720p';
}
