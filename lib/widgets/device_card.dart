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

  Color _batteryColor(int? b) {
    if (b == null) return Colors.green;
    if (b < 15) return Colors.red.shade700;
    if (b < 30) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  Color _tempColor(double? t) {
    if (t == null) return Colors.blue.shade300;
    return (t > 38) ? Colors.red.shade600 : Colors.blue.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final battVal = (battery ?? 0).clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.95), Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Left avatar + status
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _tempColor(temperature),
                            _batteryColor(battery),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.devices,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Middle info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // online badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: online
                                      ? Colors.green.shade600
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  online ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: online
                                        ? Colors.white
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Heart rate
                              Icon(
                                Icons.favorite,
                                color: Colors.pink.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                heartRate != null
                                    ? '${heartRate} bpm'
                                    : '- bpm',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 18),

                              // Temperature badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _tempColor(temperature),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  temperature != null
                                      ? '${temperature!.toStringAsFixed(1)} °C'
                                      : '- °C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Battery row with animated progress
                          Row(
                            children: [
                              const Icon(
                                Icons.battery_full,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  tween: Tween(
                                    begin: 0.0,
                                    end: battVal / 100.0,
                                  ),
                                  builder: (context, value, _) {
                                    return Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: value.clamp(0.0, 1.0),
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _batteryColor(
                                                    battery,
                                                  ).withOpacity(0.9),
                                                  _batteryColor(
                                                    battery,
                                                  ).withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                battery != null ? '${battery}%' : '-%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right action column
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
