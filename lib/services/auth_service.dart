import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _currentUser;

  String? get currentUser => _currentUser;

  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);
    if (users.containsKey(username)) return false;
    users[username] = password;
    await prefs.setString('users', json.encode(users));
    return true;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);
    if (users[username] == password) {
      _currentUser = username;
      await prefs.setString('current_user', username);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = null;
    await prefs.remove('current_user');
    notifyListeners();
  }
}
