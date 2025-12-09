// Conditional export: use web implementation when dart:html is available.
export 'mqtt_client_factory_io.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart';

// Exports: dynamic createMqttClient(String server, String clientId)
