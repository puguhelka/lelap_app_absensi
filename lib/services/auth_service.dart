import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _loading = false;
  String? _error;

  AuthService(this._api);

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    await _api.loadToken();
    if (_api.token != null) {
      _loading = true;
      notifyListeners();
      try {
        final res = await _api.get(ApiConfig.me);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          _user = User.fromJson(data['user'] ?? data, token: _api.token);
          if (data['employee'] != null) {
            _user = User.fromJson({
              ...?data['user'],
              'employeeId': data['employee']['id'],
            }, token: _api.token);
          }
        } else {
          await _api.clearToken();
        }
      } catch (_) {
        await _api.clearToken();
      }
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post(ApiConfig.login, body: {
        'email': email,
        'password': password,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        await _api.saveToken(token);
        _user = User.fromJson(data['user'], token: token);
        if (data['employee'] != null) {
          _user = User.fromJson({
            ...data['user'],
            'employeeId': data['employee']['id'],
          }, token: token);
        }
        _loading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(res.body);
        _error = data['message'] ?? 'Login gagal.';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Gagal terhubung ke server. Periksa koneksi Anda.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (_) {}
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<bool> registerDevice(String deviceId) async {
    try {
      final res = await _api.post(ApiConfig.registerDevice, body: {'deviceId': deviceId});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
