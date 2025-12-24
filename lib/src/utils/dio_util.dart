import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

bool isTransientNetworkError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.badResponse:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      // Dio uses `unknown` for various lower-level exceptions (e.g. SocketException).
      return error.response == null;
  }
}

/// Creates a default `Dio` instance suitable for this package.
///
/// - Uses `HttpClient.findProxyFromEnvironment` so `HTTPS_PROXY` / `HTTP_PROXY`
///   and `NO_PROXY` are honored.
/// - Sets conservative timeouts to avoid hanging forever on connect.
Dio createDefaultDio({
  Duration connectTimeout = const Duration(seconds: 30),
  Duration receiveTimeout = const Duration(minutes: 2),
  Duration sendTimeout = const Duration(minutes: 2),
}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
    ),
  );

  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.findProxy = HttpClient.findProxyFromEnvironment;
      return client;
    };
  }

  return dio;
}

String describeDioException(
  DioException error, {
  required String method,
  required String path,
  required String resolvedUrl,
}) {
  final status = error.response?.statusCode;
  final textBody = error.response?.data?.toString();
  final detail = (textBody == null || textBody.isEmpty)
      ? (error.message ?? error.error?.toString() ?? '')
      : textBody;

  final buffer = StringBuffer()
    ..write('Request $method $path failed: ${status ?? 'unknown'}')
    ..write(detail.isEmpty ? '' : ' $detail');

  if (resolvedUrl.isNotEmpty) {
    buffer.write(' (url: $resolvedUrl)');
  }

  final isTransient = isTransientNetworkError(error);
  if (isTransient) {
    final host = Uri.tryParse(resolvedUrl)?.host;
    final hostPart = host == null || host.isEmpty ? '' : ' (host: $host)';
    buffer.write(
      ' Network error$hostPart. If you are behind a proxy/firewall, set '
      '`HTTPS_PROXY`/`HTTP_PROXY` or pass a custom `Dio` (or override `baseUrl`).',
    );
  }

  return buffer.toString();
}
