import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';

class MQTTSettingsPage extends StatefulWidget {
  const MQTTSettingsPage({super.key});

  @override
  State<MQTTSettingsPage> createState() => _MQTTSettingsPageState();
}

class _MQTTSettingsPageState extends State<MQTTSettingsPage> {
  final _hostC = TextEditingController();
  final _portC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = Provider.of<MQTTService>(context, listen: false);
    _hostC.text = m.host;
    _portC.text = m.port.toString();
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MQTTService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('MQTT Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MQTT Broker',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure broker host/port and reconnect',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hostC,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.cloud),
                      hintText: 'Host (e.g. wss://broker.emqx.io:8084/mqtt)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _portC,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.dns),
                      hintText: 'Port (tcp port, e.g. 1883)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final host = _hostC.text.trim();
                            final port =
                                int.tryParse(_portC.text.trim()) ?? 1883;
                            await mqtt.saveSettings(host, port);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved')),
                            );
                          },
                          child: const Text('Save & Connect'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        mqtt.connected ? Icons.check_circle : Icons.cancel,
                        color: mqtt.connected ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
