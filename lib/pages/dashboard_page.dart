import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';
import '../services/db_helper.dart';
import '../models/device.dart';
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
      final mqtt = Provider.of<MQTTService>(context, listen: false);
      mqtt.connect();
      // listen for mqtt changes and persist to DB
      mqtt.addListener(() async {
        final db = Provider.of<DBHelper>(context, listen: false);
        try {
          for (final entry in mqtt.latest.entries) {
            final topic = entry.key;
            final data = entry.value;
            final Map<String, dynamic> values = {};
            if (data['heart_rate'] != null)
              values['heart_rate'] = (data['heart_rate'] as num).toInt();
            if (data['temperature'] != null)
              values['temperature'] = (data['temperature'] as num).toDouble();
            if (data['battery'] != null)
              values['battery'] = (data['battery'] as num).toInt();
            values['last_seen'] =
                data['__received_at'] ?? DateTime.now().millisecondsSinceEpoch;
            values['online'] =
                ((DateTime.now().millisecondsSinceEpoch -
                        (values['last_seen'] as int)) <
                    2 * 60 * 1000)
                ? 1
                : 0;
            if (values.isNotEmpty) {
              // try update existing device by topic, otherwise insert
              final existing = await db.getDeviceByTopic(topic);
              if (existing != null) {
                await db.updateDeviceByTopic(topic, values);
              } else {
                // create a minimal device record with topic and parsed fields
                final newDevice = Device(
                  deviceId: data['device_id']?.toString() ?? topic,
                  topic: topic,
                  name: data['device_id'] != null
                      ? 'Device ${data['device_id']}'
                      : topic,
                  heartRate: values['heart_rate'] as int?,
                  temperature: values['temperature'] as double?,
                  battery: values['battery'] as int?,
                  lastSeen: values['last_seen'] as int?,
                  online: (values['online'] as int) == 1,
                );
                await db.insertDevice(newDevice);
              }
            }
          }
        } catch (_) {}
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MQTTService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // MQTT connection status indicator
          Consumer<MQTTService>(
            builder: (context, m, _) {
              return IconButton(
                tooltip: m.connected ? 'MQTT connected' : 'MQTT disconnected',
                onPressed: () {
                  // show recent logs
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('MQTT Logs'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          children: m.recentLogs.map((e) => Text(e)).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  m.connected ? Icons.wifi : Icons.wifi_off,
                  color: m.connected ? Colors.greenAccent : Colors.grey,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Reconnect MQTT',
            onPressed: () =>
                Provider.of<MQTTService>(context, listen: false).connect(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Publish test payload',
            onPressed: () async {
              final mqtt = Provider.of<MQTTService>(context, listen: false);
              final selected = await showDialog<String?>(
                context: context,
                builder: (ctx) {
                  String topic = mqtt.topics.isNotEmpty
                      ? mqtt.topics.first
                      : '';
                  return AlertDialog(
                    title: const Text('Publish test payload'),
                    content: StatefulBuilder(
                      builder: (c, setSt) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: topic,
                              items: mqtt.topics
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setSt(() => topic = v ?? topic),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This will publish a sample JSON payload to the selected topic.',
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(topic),
                        child: const Text('Publish'),
                      ),
                    ],
                  );
                },
              );
              if (selected == null) return;
              // sample payload
              final payload = {
                'device_id': selected.split('/').last.replaceAll('device', ''),
                'heart_rate': 70 + (DateTime.now().millisecond % 10),
                'temperature': 36 + ((DateTime.now().millisecond % 50) / 10),
                'battery': 50 + (DateTime.now().millisecond % 50),
              };
              await mqtt.publishCommand(selected, payload);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test payload published')),
              );
            },
            icon: const Icon(Icons.send),
          ),
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
      body: Stack(
        children: [
          // decorative background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // soft floating blobs
          Positioned(
            left: -80,
            top: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {},
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header summary
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Live status of your devices',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // small controls
                      Row(
                        children: [
                          Consumer<MQTTService>(
                            builder: (context, m, _) {
                              return IconButton(
                                tooltip: m.connected
                                    ? 'MQTT connected'
                                    : 'MQTT disconnected',
                                onPressed: () {},
                                icon: Icon(
                                  m.connected ? Icons.wifi : Icons.wifi_off,
                                  color: m.connected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: () => Provider.of<MQTTService>(
                              context,
                              listen: false,
                            ).connect(),
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // grid of device cards
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxis = constraints.maxWidth > 1000
                            ? 3
                            : (constraints.maxWidth > 700 ? 2 : 1);
                        final topics = mqtt.topics;
                        return GridView.count(
                          crossAxisCount: crossAxis,
                          childAspectRatio: 3.4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: topics.map((topic) {
                            final data = mqtt.latest[topic];
                            final name =
                                data != null && data['device_id'] != null
                                ? 'Device ${data['device_id']}'
                                : topic;
                            final heart =
                                data != null && data['heart_rate'] != null
                                ? (data['heart_rate'] as num).toInt()
                                : null;
                            final temp =
                                data != null && data['temperature'] != null
                                ? (data['temperature'] as num).toDouble()
                                : null;
                            final batt = data != null && data['battery'] != null
                                ? (data['battery'] as num).toInt()
                                : null;
                            final online =
                                (data != null && data['__received_at'] != null)
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
                        );
                      },
                    ),
                  ),
                ],
              ), // end Column
            ), // end Padding
          ), // end RefreshIndicator
        ], // end Stack children
      ), // end Stack
    );
  }
}
