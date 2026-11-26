// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String> fetchTextUrl(
  String url, {
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 15),
}) async {
  final req = await html.HttpRequest.request(
    url,
    method: 'GET',
    requestHeaders: headers,
  ).timeout(timeout);
  if (req.status != 200) {
    throw Exception('HTTP ${req.status}');
  }
  return req.responseText ?? '';
}

Future<List<int>?> fetchBytesUrl(
  String url, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  return null;
}
