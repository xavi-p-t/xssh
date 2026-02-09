import 'dart:convert';
import 'dart:io';
import 'package:xssh/portRules.dart';
import 'package:flutter/material.dart';

class UserData {
  String name;
  String server;
  int port;
  String? key;
  List<PortRule> rules;

  UserData({
    required this.name,
    required this.server,
    required this.port,
    required this.key,
    required this.rules,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'server': server,
    'port': port,
    'key': key,
    'rules': rules.map((r) => r.toJson()).toList(),
  };

  static UserData fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      server: json['server'],
      port: json['port'],
      key: json['key'],
      rules: (json['rules'] as List<dynamic>)
          .map((r) => PortRule.fromJson(r))
          .toList(),
    );
  }
}


class Storage {
  static Future<String> _getFilePath() async {
    final directory = Directory('./data');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return '${directory.path}/user_data.json';
  }

  static Future<List<UserData>> loadUserData() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!file.existsSync()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(content);

      return jsonData.map((data) => UserData.fromJson(data)).toList();
    } catch (e) {
      print("Error al cargar los datos: $e");
      return [];
    }
  }

  static Future<void> saveUserData(List<UserData> users) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!file.existsSync()) {
        await file.create(recursive: true);
      }

      final List<Map<String, dynamic>> jsonData =
          users.map((user) => user.toJson()).toList();

      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      print("Error al guardar los datos: $e");
    }
  }
}
