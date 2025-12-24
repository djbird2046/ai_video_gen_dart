import 'dart:convert';
import 'dart:io';

String? maybeEncodeFile(Object? value, {bool addDataPrefix = false}) {
  if (value is! String || value.isEmpty) return value as String?;
  final path = normalizeFilePath(value);
  if (path == null) return value;
  final file = File(path);
  if (!file.existsSync()) return value;
  final bytes = file.readAsBytesSync();
  final b64 = base64Encode(bytes);
  if (!addDataPrefix) return b64;
  final mime = guessMime(path);
  return 'data:$mime;base64,$b64';
}

List<String>? maybeEncodeFiles(
  List<String> values, {
  bool addDataPrefix = false,
}) {
  if (values.isEmpty) return values;
  return values
      .map((v) => maybeEncodeFile(v, addDataPrefix: addDataPrefix) ?? v)
      .toList();
}

String? normalizeFilePath(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return null;
  }
  if (value.startsWith('data:')) return null;
  if (value.startsWith('file://')) {
    return Uri.parse(value).toFilePath();
  }
  return value;
}

List<String>? normalizeStringList(Object? raw) {
  if (raw == null) return null;
  if (raw is List) {
    return raw.whereType<String>().toList();
  }
  if (raw is String) {
    return <String>[raw];
  }
  return null;
}

String guessMime(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}
