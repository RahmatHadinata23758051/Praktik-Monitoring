import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final int? heartRate;
  final double? temperature;
  final int? battery;
  final bool online;

  const DeviceCard({
    super.key,
    required this.name,
    this.heartRate,
    this.temperature,
    this.battery,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    final tempColor = (temperature != null && temperature! > 38)
        ? Colors.red
        : Colors.blue;
    Color batteryColor = Colors.green;
    if (battery != null) {
      if (battery! < 15)
        batteryColor = Colors.red;
      else if (battery! < 30)
        batteryColor = Colors.yellow;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  color: online ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Heart Rate: ${heartRate ?? '-'} bpm')),
                Expanded(
                  child: Text(
                    'Temp: ${temperature?.toStringAsFixed(1) ?? '-'} °C',
                    style: TextStyle(color: tempColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Battery: '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (battery ?? 0) / 100.0,
                    color: batteryColor,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${battery ?? '-'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
