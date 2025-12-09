import 'package:mqtt_client/mqtt_server_client.dart';

/// Returns a platform-appropriate MQTT client instance for non-web (IO).
dynamic createMqttClient(String server, String clientId) {
  return MqttServerClient(server, clientId);
}
