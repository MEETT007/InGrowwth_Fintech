import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CustomerDetails {
  CustomerDetails(Map<String, dynamic> response)
    : values = {
        'customerId': response['customerId'],
        for (final section in [
          'basicInformation',
          'panInformation',
          'addressInformation',
          'employmentInformation',
          'creditProfile',
        ])
          if (response[section] is Map<String, dynamic>)
            ...response[section] as Map<String, dynamic>,
      },
      homeLoans = (response['homeLoans'] as List? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  final List<Map<String, dynamic>> homeLoans;
  final Map<String, dynamic> values;
  String? value(String key) {
    final v = values[key]?.toString();
    return v == null || v.trim().isEmpty ? null : v;
  }
}

class PanLookupService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
  );
  final http.Client client;
  PanLookupService({http.Client? client}) : client = client ?? http.Client();
  String? _token;
  static String normalize(String input) => input.trim().toUpperCase();
  static bool valid(String input) =>
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(normalize(input));
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final timer = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('[Employee API] POST $baseUrl/api/employee/$path started');
    }
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/api/employee/$path'),
            headers: {
              'Content-Type': 'application/json',
              if (_token != null) 'Authorization': 'Bearer $_token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) {
        debugPrint(
          '[Employee API] POST $path status=${response.statusCode} durationMs=${timer.elapsedMilliseconds} request=${response.headers['x-request-id'] ?? 'unavailable'}',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Request failed. Please sign in again.',
        );
      }
      return data;
    } on TimeoutException {
      throw Exception('Backend took too long to respond. Please try again.');
    } on http.ClientException {
      if (kDebugMode) {
        debugPrint('[Employee API] $path connection failed');
      }
      throw Exception(
        'Backend unavailable. Check that the backend is running and the API address is correct.',
      );
    } on FormatException {
      throw Exception('Unexpected backend response. Check the API address.');
    }
  }

  Future<void> signIn(String mobile, String otp) async {
    _token =
        (await _post('demo-session', {'mobile': mobile, 'otp': otp}))['token']
            as String;
  }

  Future<CustomerDetails> lookup(String input) async {
    if (!valid(input)) {
      throw Exception('Enter a valid PAN, for example ABCDE1234F.');
    }
    final response = await _post('customers/pan-lookup', {
      'panNumber': normalize(input),
    });
    return CustomerDetails(response['data'] as Map<String, dynamic>);
  }

  void close() => client.close();
}
