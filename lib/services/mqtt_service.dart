import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart' show MqttServerClient;
import 'package:mqtt_client/mqtt_browser_client.dart' show MqttBrowserClient;
import 'package:shared_preferences/shared_preferences.dart';

class MQTTService extends ChangeNotifier {
  // Use a dynamic client because web uses MqttBrowserClient while mobile/desktop use MqttServerClient
  dynamic _client;
  String host = 'broker.emqx.io';
  int port = 1883;
  bool connected = false;

  // latest data by topic
  final Map<String, Map<String, dynamic>> latest = {};

  Timer? _watchdog;

  final List<String> topics = List.generate(
    5,
    (i) => 'data/device/device00${i + 1}',
  );

  MQTTService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    host = prefs.getString('mqtt_host') ?? host;
    port = prefs.getInt('mqtt_port') ?? port;
    notifyListeners();
  }

  Future<void> saveSettings(String h, int p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_host', h);
    await prefs.setInt('mqtt_port', p);
    host = h;
    port = p;
    await connect();
    notifyListeners();
  }

  Future<void> connect() async {
    await _disconnect();
    if (kIsWeb) {
      // On web use WebSocket endpoint. If host looks like ws:// or wss://, use it; otherwise default to EMQX ws port
      final endpoint = (host.startsWith('ws://') || host.startsWith('wss://'))
          ? host
          : 'ws://$host:8083/mqtt';
      _client = MqttBrowserClient(
        endpoint,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      _client = MqttServerClient(
        host,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      );
      _client.port = port;
    }

    try {
      _client.logging(on: false);
      _client.keepAlivePeriod = 20;
      _client.onDisconnected = _onDisconnected;

      final connMess = MqttConnectMessage().startClean();
      _client.connectionMessage = connMess;
      await _client.connect();
      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        connected = true;
        _subscribeAll();
        _startWatchdog();
        notifyListeners();
      } else {
        connected = false;
        try {
          _client.disconnect();
        } catch (_) {}
      }
    } catch (e) {
      connected = false;
      try {
        _client?.disconnect();
      } catch (_) {}
    }
  }

  void _onDisconnected() {
    connected = false;
    notifyListeners();
  }

  Future<void> _disconnect() async {
    _watchdog?.cancel();
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
    connected = false;
  }

  void _subscribeAll() {
    if (_client == null) return;
    for (final t in topics) {
      _client!.subscribe(t, MqttQos.atMostOnce);
    }

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      _handlePayload(c[0].topic, payload);
    });
  }

  void _handlePayload(String topic, String payload) {
    try {
      final Map<String, dynamic> data = json.decode(payload);
      data['__topic'] = topic;
      data['__received_at'] = DateTime.now().millisecondsSinceEpoch;
      latest[topic] = data;
      notifyListeners();
    } catch (e) {
      // ignore parse errors
    }
  }

  Future<void> publishCommand(
    String topic,
    Map<String, dynamic> payload,
  ) async {
    if (_client == null) await connect();
    if (_client == null) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode(payload));
    _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      bool changed = false;
      latest.forEach((topic, data) {
        final last = data['__received_at'] as int?;
        if (last != null) {
          final diff = now - last;
          final wasOnline = data['__online'] == true;
          final isOnline = diff < 2 * 60 * 1000; // 2 minutes
          if (wasOnline != isOnline) {
            data['__online'] = isOnline;
            changed = true;
          }
        }
      });
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _client?.disconnect();
    super.dispose();
  }
}
