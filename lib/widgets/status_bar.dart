import 'package:flutter/material.dart';

class DeviceStatusBar extends StatelessWidget {
  final Map<String, String>? diskSpace;
  final VoidCallback onRestart;

  const DeviceStatusBar({super.key, required this.diskSpace, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (diskSpace != null) 
            Text('Free space: Root - ${diskSpace!['/']} • Home - ${diskSpace!['/home']}'),
          if (diskSpace == null) 
            Text('Free space on device: (device not connected)'),
          Spacer(),
          Text("Click to restart device: "),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restart XOCHITL',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}
