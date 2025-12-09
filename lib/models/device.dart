class Device {
  int? id;
  String deviceId; // like "device001"
  String topic; // data/device/device001
  String name;
  int? heartRate;
  double? temperature;
  int? battery;
  int? lastSeen; // epoch millis
  bool? online;

  Device({
    this.id,
    required this.deviceId,
    required this.topic,
    required this.name,
    this.heartRate,
    this.temperature,
    this.battery,
    this.lastSeen,
    this.online,
  });

  factory Device.fromMap(Map<String, dynamic> m) => Device(
    id: m['id'] as int?,
    deviceId: m['device_id'] as String,
    topic: m['topic'] as String,
    name: m['name'] as String,
    heartRate: m['heart_rate'] as int?,
    temperature: m['temperature'] == null
        ? null
        : (m['temperature'] as num).toDouble(),
    battery: m['battery'] as int?,
    lastSeen: m['last_seen'] as int?,
    online: (m['online'] == 1),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'device_id': deviceId,
    'topic': topic,
    'name': name,
    'heart_rate': heartRate,
    'temperature': temperature,
    'battery': battery,
    'last_seen': lastSeen,
    'online': (online == true) ? 1 : 0,
  };
}
