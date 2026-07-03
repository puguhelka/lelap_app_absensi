import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  String _baseUrl;
  String? _token;
  static const String _tokenKey = 'auth_token';

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<http.Response> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    return http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return http.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null).timeout(ApiConfig.timeout);
  }

  Future<http.Response> postMultipart(String path, {Map<String, String>? fields, List<File>? files, String? fileField}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (fields != null) request.fields.addAll(fields);
    if (files != null && fileField != null) {
      for (final file in files) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }
    }
    final streamed = await request.send().timeout(const Duration(minutes: 2));
    return http.Response.fromStream(streamed);
  }

  bool isUnauthorized(http.Response response) => response.statusCode == 401;
}
