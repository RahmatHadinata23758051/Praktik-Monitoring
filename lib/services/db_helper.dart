import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/device.dart';

class DBHelper {
  Database? _db;
  // in-memory fallback for web
  final List<Device> _memoryDevices = [];

  Future<void> init() async {
    if (kIsWeb) {
      // web environment: do not use sqflite, keep devices in memory
      _memoryDevices.clear();
      return;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'monitoring.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        topic TEXT NOT NULL,
        name TEXT NOT NULL,
        heart_rate INTEGER,
        temperature REAL,
        battery INTEGER,
        last_seen INTEGER,
        online INTEGER DEFAULT 0
      )
      ''');
      },
    );
  }

  Future<int> insertDevice(Device d) async {
    if (kIsWeb) {
      final newId = (_memoryDevices.isEmpty)
          ? 1
          : (_memoryDevices
                    .map((e) => e.id ?? 0)
                    .reduce((a, b) => a > b ? a : b) +
                1);
      d.id = newId;
      _memoryDevices.add(d);
      return newId;
    }
    return await _db!.insert('devices', d.toMap());
  }

  Future<List<Device>> getDevices() async {
    if (kIsWeb) {
      return List<Device>.from(_memoryDevices);
    }
    final rows = await _db!.query('devices');
    return rows.map((r) => Device.fromMap(r)).toList();
  }

  Future<int> updateDeviceByTopic(
    String topic,
    Map<String, dynamic> values,
  ) async {
    if (kIsWeb) {
      var count = 0;
      for (var i = 0; i < _memoryDevices.length; i++) {
        if (_memoryDevices[i].topic == topic) {
          final m = _memoryDevices[i].toMap();
          values.forEach((k, v) => m[k] = v);
          _memoryDevices[i] = Device.fromMap(m);
          count++;
        }
      }
      return count;
    }
    return await _db!.update(
      'devices',
      values,
      where: 'topic = ?',
      whereArgs: [topic],
    );
  }

  Future<Device?> getDeviceByTopic(String topic) async {
    if (kIsWeb) {
      try {
        return _memoryDevices.firstWhere((d) => d.topic == topic);
      } catch (_) {
        return null;
      }
    }
    final rows = await _db!.query(
      'devices',
      where: 'topic = ?',
      whereArgs: [topic],
    );
    if (rows.isEmpty) return null;
    return Device.fromMap(rows.first);
  }
}
