import 'package:flutter/material.dart';
import '../services/device_connection_manager.dart';
import 'dart:io';

class DeviceSidebar extends StatefulWidget {
  final void Function(String path) onCardTap;
  final void Function(String path, File droppedFile) onFileDropped;

  const DeviceSidebar({
    super.key,
    required this.onCardTap,
    required this.onFileDropped,
  });

  @override
  State<DeviceSidebar> createState() => _DeviceSidebarState();
}

class _DeviceSidebarState extends State<DeviceSidebar> {
  String _ipAddress = '';
  String _password = '';
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;
  final DeviceConnectionManager _deviceManager = DeviceConnectionManager();

  Future<void> _connectToDevice() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await _deviceManager.connect(_ipAddress, _password);
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Failed to connect';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _disconnect() {
    _deviceManager.disconnect();
    setState(() {
      _isConnected = false;
      _ipAddress = '';
      _password = '';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DashboardDropCard(
            title: 'Templates',
            icon: Icons.description_outlined,
            dropPath: '/templates',
            onTap: () => widget.onCardTap('/templates'),
            onFileDropped: widget.onFileDropped,
          ),
          const SizedBox(height: 16),
          _DashboardDropCard(
            title: 'Splash Screens',
            icon: Icons.image_outlined,
            dropPath: '/splash',
            onTap: () => widget.onCardTap('/splash'),
            onFileDropped: widget.onFileDropped,
          ),
          const Spacer(),
          const Divider(),
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isConnected
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            'Connected to\n$_ipAddress',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _disconnect,
                            icon: const Icon(Icons.logout),
                            label: const Text('Disconnect'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Device IP',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _ipAddress = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            obscureText: true,
                            onChanged: (value) {
                              _password = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isConnecting ? null : _connectToDevice,
                            icon: _isConnecting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _isConnecting
                                  ? 'Connecting...'
                                  : _errorMessage ?? 'Not Connected',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDropCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String dropPath;
  final VoidCallback onTap;
  final void Function(String path, File droppedFile) onFileDropped;

  const _DashboardDropCard({
    super.key,
    required this.title,
    required this.icon,
    required this.dropPath,
    required this.onTap,
    required this.onFileDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<FileSystemEntity>(
      onAccept: (fileEntity) {
        if (fileEntity is File) {
          onFileDropped(dropPath, fileEntity);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isHighlighted ? Colors.blue.shade50 : null,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                children: [
                  Icon(icon, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}