import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BankingApi {
  BankingApi({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://127.0.0.1:8080',
          );
  final String baseUrl;
  final HttpClient _client = HttpClient();
  final Map<String, Cookie> _cookies = {};
  String _csrf = '';
  void _headers(HttpClientRequest request) {
    request.cookies.addAll(_cookies.values);
    request.headers.set('X-XSRF-TOKEN', _csrf);
  }

  Future<dynamic> request(String path, [Map<String, dynamic>? body]) async {
    final request = await _client
        .openUrl(body == null ? 'GET' : 'POST', Uri.parse('$baseUrl/api/$path'))
        .timeout(const Duration(seconds: 15));
    _headers(request);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 20));
    for (final cookie in response.cookies) {
      _cookies[cookie.name] = cookie;
    }
    final data = jsonDecode(await utf8.decoder.bind(response).join());
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Request could not be completed.');
    }
    if (path == 'auth/session') {
      _csrf = data['csrf'];
    }
    return data;
  }

  Stream<String> updates() async* {
    final request = await _client.getUrl(Uri.parse('$baseUrl/api/events'));
    _headers(request);
    request.headers.set('Accept', 'text/event-stream');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Live connection unavailable.');
    }
    await for (final line
        in response.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line == 'event:case-update') {
        yield 'changed';
      }
    }
  }

  void dispose() {
    _client.close(force: true);
  }
}
