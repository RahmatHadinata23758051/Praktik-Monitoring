import 'package:mqtt_client/mqtt_browser_client.dart';

/// Returns a platform-appropriate MQTT client instance for web (browser).
dynamic createMqttClient(String server, String clientId) {
  return MqttBrowserClient(server, clientId);
}
