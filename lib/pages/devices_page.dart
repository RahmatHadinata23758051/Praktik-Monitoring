import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db_helper.dart';
import '../models/device.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<Device> _devices = [];

  Future<void> _load() async {
    final db = Provider.of<DBHelper>(context, listen: false);
    final list = await db.getDevices();
    setState(() => _devices = list);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, i) {
          final d = _devices[i];
          return ListTile(
            title: Text(d.name),
            subtitle: Text(d.topic),
            trailing: Icon(
              d.online == true ? Icons.check_circle : Icons.remove_circle,
              color: d.online == true ? Colors.green : Colors.grey,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _DeviceAddPage()),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DeviceAddPage extends StatefulWidget {
  const _DeviceAddPage({super.key});

  @override
  State<_DeviceAddPage> createState() => _DeviceAddPageState();
}

class _DeviceAddPageState extends State<_DeviceAddPage> {
  final _form = GlobalKey<FormState>();
  final _idC = TextEditingController();
  final _topicC = TextEditingController();
  final _nameC = TextEditingController();

  @override
  void dispose() {
    _idC.dispose();
    _topicC.dispose();
    _nameC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _idC,
                decoration: const InputDecoration(
                  labelText: 'Device ID (eg 001)',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _topicC,
                decoration: const InputDecoration(
                  labelText: 'Topic (eg data/device/device001)',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final db = Provider.of<DBHelper>(context, listen: false);
                  final d = Device(
                    deviceId: _idC.text.trim(),
                    topic: _topicC.text.trim(),
                    name: _nameC.text.trim(),
                  );
                  await db.insertDevice(d);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
