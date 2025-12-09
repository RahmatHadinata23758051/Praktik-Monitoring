import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MQTTService extends ChangeNotifier {
  // Use a dynamic client because web uses MqttBrowserClient while mobile/desktop use MqttServerClient
  dynamic _client;
  String host = 'broker.emqx.io';
  int port = 1883;
  bool connected = false;
  // per-topic subscribed state
  final Map<String, bool> subscribed = {};
  // small recent event logs for debugging (most recent first)
  final List<String> recentLogs = [];
  void _addLog(String s) {
    final ts = DateTime.now().toIso8601String();
    recentLogs.insert(0, '[$ts] $s');
    if (recentLogs.length > 200) recentLogs.removeRange(200, recentLogs.length);
    notifyListeners();
  }

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;

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

    // prepare a connection endpoint description for logs
    final connEndpoint = kIsWeb
        ? ((host.startsWith('ws://') || host.startsWith('wss://'))
              ? host
              : 'wss://$host:8084/mqtt')
        : '$host:$port';

    bool alreadyConnected = false;

    if (kIsWeb) {
      // try a few websocket endpoint variants (wss/ws, with and without /mqtt)
      final List<String> candidates = [];
      if (host.startsWith('ws://') || host.startsWith('wss://'))
        candidates.add(host);
      candidates.add('wss://$host:8084/mqtt');
      candidates.add('ws://$host:8083/mqtt');
      candidates.add('wss://$host:8084');
      candidates.add('ws://$host:8083');
      // Add known-public test brokers to help diagnose network/browser issues
      candidates.add('wss://test.mosquitto.org:8081');
      candidates.add('ws://test.mosquitto.org:8080');

      _addLog('Web mode: trying websocket endpoints: ${candidates.join(', ')}');

      dynamic connectedClient;
      String? chosenEndpoint;
      for (final ep in candidates) {
        try {
          _addLog('Trying endpoint: $ep');
          final temp = createMqttClient(
            ep,
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
          );
          temp.logging(on: true);
          // ensure port is set on the browser client so the library does not override it
          try {
            final uri = Uri.parse(ep);
            if (uri.hasPort) {
              try {
                temp.port = uri.port;
                _addLog('Set temp.port = ${uri.port} for endpoint $ep');
              } catch (_) {}
            }
          } catch (_) {}
          temp.keepAlivePeriod = 20;
          temp.onDisconnected = _onDisconnected;
          try {
            temp.onConnected = () {
              _addLog('MQTT connected (temp) for $ep');
            };
          } catch (_) {}
          try {
            temp.onSubscribed = (String topic) {
              _addLog('Subscribed (temp): $topic');
            };
          } catch (_) {}

          await temp.connect();
          final st = temp.connectionStatus;
          _addLog('Attempt result for $ep -> ${st?.toString() ?? 'null'}');
          if (st != null && st.state == MqttConnectionState.connected) {
            connectedClient = temp;
            chosenEndpoint = ep;
            break;
          } else {
            try {
              temp.disconnect();
            } catch (_) {}
          }
        } catch (e, st) {
          _addLog('Endpoint $ep failed: $e');
          _addLog('Stack: $st');
        }
      }

      if (connectedClient != null) {
        _client = connectedClient;
        alreadyConnected = true;
        _addLog('Using websocket endpoint: $chosenEndpoint');
      } else {
        _client = null;
        _addLog('No websocket endpoint succeeded');
        _addLog(
          'If all endpoints fail: periksa Developer Console di browser untuk error WebSocket/TLS/CORS, atau coba ganti host menjadi "wss://broker.emqx.io:8084/mqtt" di Settings.',
        );
      }
    } else {
      // create IO client via factory (returns MqttServerClient)
      _client = createMqttClient(
        host,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      );
      try {
        _client.port = port;
      } catch (_) {}
    }

    _addLog('Attempting MQTT connect to $connEndpoint');
    try {
      if (_client == null) {
        _addLog('No MQTT client available to connect');
        _scheduleReconnect();
        return;
      }

      _client.logging(on: true);
      _client.keepAlivePeriod = 20;
      _client.onDisconnected = _onDisconnected;
      try {
        _client.onConnected = () {
          _addLog('MQTT connected');
          connected = true;
          notifyListeners();
        };
      } catch (_) {}
      try {
        _client.onSubscribed = (String topic) {
          subscribed[topic] = true;
          _addLog('Subscribed: $topic');
        };
      } catch (_) {}

      final connMess = MqttConnectMessage().startClean();
      _client.connectionMessage = connMess;

      if (!alreadyConnected) {
        await _client.connect();
      } else {
        _addLog('Client already connected by candidate probe');
      }

      final status = _client.connectionStatus;
      _addLog('ConnectionStatus: ${status?.toString() ?? 'null'}');
      if (status != null && status.state == MqttConnectionState.connected) {
        _reconnectAttempts = 0;
        connected = true;
        _addLog('Connection established. Subscribing to topics...');
        _subscribeAll();
        _startWatchdog();
        notifyListeners();
      } else {
        connected = false;
        final rc = status?.returnCode ?? 'unknown';
        _addLog('Connect failed, returnCode=$rc');
        try {
          _client.disconnect();
        } catch (_) {}
        _scheduleReconnect();
      }
    } catch (e, st) {
      connected = false;
      _addLog('Connect exception: $e');
      _addLog('Stack: $st');
      try {
        _client?.disconnect();
      } catch (_) {}
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      _addLog(
        'Max reconnect attempts reached ($_reconnectAttempts). Will stop retrying.',
      );
      return;
    }
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    _addLog(
      'Scheduling reconnect attempt #$_reconnectAttempts in ${delay.inSeconds}s',
    );
    Timer(delay, () async {
      if (connected) return;
      await connect();
    });
  }

  void _onDisconnected() {
    connected = false;
    _addLog('MQTT disconnected. status=${_client?.connectionStatus}');
    notifyListeners();
    // try reconnect
    _scheduleReconnect();
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
      subscribed[t] = false;
      try {
        _client!.subscribe(t, MqttQos.atMostOnce);
      } catch (e) {
        _addLog('Subscribe error for $t: $e');
      }
    }

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      _addLog('Received on ${c[0].topic}: $payload');
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
      _addLog('Payload parse error for $topic: $e');
      _addLog('Raw payload: $payload');
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
