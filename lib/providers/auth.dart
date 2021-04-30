import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiresDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiresDate != null &&
        _expiresDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyA0T-yCEsPx3Bf7IaFsx2-TbgkhTXfyz7k');

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        var errorMessage = 'Authentication failed.';
        final responseErrorMessage = responseData['error']['message'] as String;

        if (responseErrorMessage.contains('EMAIL_EXISTS')) {
          errorMessage = 'This email is already in use.';
        } else if (responseErrorMessage.contains('EMAIL_NOT_FOUND')) {
          errorMessage = 'This email does\'nt exist.';
        } else if (responseErrorMessage.contains('INVALID_EMAIL')) {
          errorMessage = 'Please provide a valid email.';
        } else if (responseErrorMessage.contains('WEAK_PASSWORD')) {
          errorMessage = 'This password is too weak';
        } else if (responseErrorMessage.contains('INVALID_PASSWORD')) {
          errorMessage = 'Invalid password';
        }

        throw HttpException(errorMessage);
      }

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiresDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
      _autoLogout();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiresDate.toIso8601String(),
      });
      prefs.setString('userData', userData);

      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;

    final data =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    final expiryDate = DateTime.parse(data['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) return false;

    _token = data['token'];
    _userId = data['userId'];
    _expiresDate = expiryDate;

    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    _token = null;
    _expiresDate = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    notifyListeners();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    final timeToLogout = _expiresDate.difference(DateTime.now()).inSeconds;

    _authTimer = Timer(Duration(seconds: timeToLogout), logout);
  }
}
