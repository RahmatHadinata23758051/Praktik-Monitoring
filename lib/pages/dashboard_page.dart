import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';
import '../services/db_helper.dart';
import '../widgets/device_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // connect MQTT on entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MQTTService>(context, listen: false).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MQTTService>(context);
    final db = Provider.of<DBHelper>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/devices'),
            icon: const Icon(Icons.devices),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/mqtt_settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: mqtt.topics.map((topic) {
            final data = mqtt.latest[topic];
            final name = data != null && data['device_id'] != null
                ? 'Device ${data['device_id']}'
                : topic;
            final heart = data != null && data['heart_rate'] != null
                ? (data['heart_rate'] as num).toInt()
                : null;
            final temp = data != null && data['temperature'] != null
                ? (data['temperature'] as num).toDouble()
                : null;
            final batt = data != null && data['battery'] != null
                ? (data['battery'] as num).toInt()
                : null;
            final online = (data != null && data['__received_at'] != null)
                ? ((DateTime.now().millisecondsSinceEpoch -
                          (data['__received_at'] as int)) <
                      2 * 60 * 1000)
                : false;
            return DeviceCard(
              name: name,
              heartRate: heart,
              temperature: temp,
              battery: batt,
              online: online,
            );
          }).toList(),
        ),
      ),
    );
  }
}
