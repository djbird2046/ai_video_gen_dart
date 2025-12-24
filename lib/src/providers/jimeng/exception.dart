class JimengError {
  const JimengError({
    required this.httpCode,
    required this.code,
    required this.message,
    required this.description,
  });

  final int httpCode;
  final int code;
  final String message;
  final String description;

  String format([String? apiMessage]) {
    final base = (apiMessage == null || apiMessage.isEmpty)
        ? message
        : apiMessage;
    if (description.isEmpty) return base;
    return '$base: $description';
  }
}

class JimengErrors {
  static const Map<int, JimengError> _errors = {
    10000: JimengError(
      httpCode: 200,
      code: 10000,
      message: 'OK',
      description: '请求成功',
    ),
    50411: JimengError(
      httpCode: 400,
      code: 50411,
      message: 'Pre Img Risk Not Pass',
      description: '输入图片前审核未通过',
    ),
    50511: JimengError(
      httpCode: 400,
      code: 50511,
      message: 'Post Img Risk Not Pass',
      description: '输出图片后审核未通过',
    ),
    50412: JimengError(
      httpCode: 400,
      code: 50412,
      message: 'Text Risk Not Pass',
      description: '输入文本前审核未通过',
    ),
    50512: JimengError(
      httpCode: 400,
      code: 50512,
      message: 'Post Text Risk Not Pass',
      description: '输出文本后审核未通过',
    ),
    50413: JimengError(
      httpCode: 400,
      code: 50413,
      message: 'Post Text Risk Not Pass',
      description: '输入文本含敏感词、版权词等审核不通过',
    ),
    50516: JimengError(
      httpCode: 400,
      code: 50516,
      message: 'Post Video Risk Not Pass',
      description: '输出视频后审核未通过',
    ),
    50517: JimengError(
      httpCode: 400,
      code: 50517,
      message: 'Post Audio Risk Not Pass',
      description: '输出音频后审核未通过',
    ),
    50518: JimengError(
      httpCode: 400,
      code: 50518,
      message: 'Pre Img Risk Not Pass: Copyright',
      description: '输入版权图前审核未通过',
    ),
    50519: JimengError(
      httpCode: 400,
      code: 50519,
      message: 'Post Img Risk Not Pass: Copyright',
      description: '输出版权图后审核未通过',
    ),
    50520: JimengError(
      httpCode: 400,
      code: 50520,
      message: 'Risk Internal Error',
      description: '审核服务异常',
    ),
    50521: JimengError(
      httpCode: 400,
      code: 50521,
      message: 'Antidirt Internal Error',
      description: '版权词服务异常',
    ),
    50522: JimengError(
      httpCode: 400,
      code: 50522,
      message: 'Image Copyright Internal Error',
      description: '版权图服务异常',
    ),
    50429: JimengError(
      httpCode: 429,
      code: 50429,
      message: 'Request Has Reached API Limit, Please Try Later',
      description: 'QPS超限',
    ),
    50430: JimengError(
      httpCode: 429,
      code: 50430,
      message: 'Request Has Reached API Concurrent Limit, Please Try Later',
      description: '并发超限',
    ),
    50500: JimengError(
      httpCode: 500,
      code: 50500,
      message: 'Internal Error',
      description: '内部错误',
    ),
    50501: JimengError(
      httpCode: 500,
      code: 50501,
      message: 'Internal RPC Error',
      description: '内部算法错误',
    ),
  };

  static JimengError? fromCode(int? code) {
    if (code == null) return null;
    return _errors[code];
  }

  static String? describe(int? code, [String? apiMessage]) {
    final error = fromCode(code);
    return error?.format(apiMessage);
  }
}
