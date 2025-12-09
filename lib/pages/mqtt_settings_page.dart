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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
              controller: _hostC,
              decoration: const InputDecoration(labelText: 'Host'),
            ),
            TextFormField(
              controller: _portC,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final host = _hostC.text.trim();
                final port = int.tryParse(_portC.text.trim()) ?? 1883;
                await mqtt.saveSettings(host, port);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved')));
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Connected: '),
                Icon(
                  mqtt.connected ? Icons.check_circle : Icons.cancel,
                  color: mqtt.connected ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
