import 'dart:convert';
import 'dart:io';

Future<String> fetchTextUrl(
  String url, {
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 15),
}) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
    headers.forEach((k, v) => req.headers.set(k, v));
    final res = await req.close().timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

Future<List<int>?> fetchBytesUrl(
  String url, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final res = await req.close().timeout(timeout);
    if (res.statusCode != 200) return null;
    return await res.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}
