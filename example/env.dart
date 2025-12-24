import 'dart:io';

/// Loads credentials from process env or a local `.env` file.
/// Returns the first non-empty match from [key] or any of [altKeys].
String env(
  String key, {
  List<String> altKeys = const <String>[],
  String defaultValue = '',
}) {
  for (final candidate in <String>[key, ...altKeys]) {
    final fromProcess = Platform.environment[candidate];
    if (fromProcess != null && fromProcess.isNotEmpty) {
      return fromProcess;
    }

    final fromFile = _dotenv[candidate];
    if (fromFile != null && fromFile.isNotEmpty) {
      return fromFile;
    }
  }
  return defaultValue;
}

final Map<String, String> _dotenv = _loadEnvFile();

Map<String, String> _loadEnvFile() {
  final file = File('.env');
  if (!file.existsSync()) return <String, String>{};

  final lines = file.readAsLinesSync();
  final Map<String, String> values = <String, String>{};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator <= 0) continue;

    final key = trimmed.substring(0, separator).trim();
    final value = trimmed.substring(separator + 1).trim();
    values[key] = value;
  }
  return values;
}
