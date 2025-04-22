import 'package:flutter/material.dart';
import '../services/device_connection_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:markup/dialogs/password_dialog.dart';  // <-- Import your dialog function

class DeviceSidebar extends StatefulWidget {

  const DeviceSidebar({
    super.key
  });

  @override
  State<DeviceSidebar> createState() => _DeviceSidebarState();
}

class _DeviceSidebarState extends State<DeviceSidebar> {
  String _ipAddress = '';
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isUploadingTemplate = false;
  String? _errorMessage;
  final DeviceConnectionManager _deviceManager = DeviceConnectionManager();

  Timer? _connectionCheckerTimer;
  
  Future<void> _connectToDevice() async {
    PasswordDialogResult? result;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final deviceManager = DeviceConnectionManager();

    // To try retrieving a password:
    String? password = await deviceManager.getSavedPassword();

    if (password == null) {
      if(mounted) { // make linter happy
        result = await showPasswordDialog(context);
      } else {
        return;
      }
      if(!mounted) return; // actually prevent against zombie context.

      if (result != null) {
        if (result.rememberPassword) {
          await deviceManager.savePassword(result.password);
        }
      } else {
        setState(() {
          _isConnecting = false;
        });
      }
    }

    try {
      await _deviceManager.connect(_ipAddress, password);
      setState(() {
        _isConnected = true;
        _startConnectionChecker();
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

  Future<void> _handleTemplateFileDrop(List<File> droppedFiles) async {
    if (!_isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected to device.')),
        );
      }
      return;
    }

    final validSvgFiles = droppedFiles.where((file) => file.path.toLowerCase().endsWith('.svg')).toList();
    if (validSvgFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid SVG files found.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isUploadingTemplate = true;
      });
    }

    try {
      for (final droppedFile in validSvgFiles) {
        final templateName = droppedFile.uri.pathSegments.last.replaceAll('.svg', '');
        final templateFilename = templateName;

        await _deviceManager.uploadTemplateAndUpdateJson(
          localSvgFile: droppedFile,
          templateName: templateName,
          templateFilename: templateFilename,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${validSvgFiles.length} template(s) uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingTemplate = false;
        });
      }
    }
  }

  Future<void> _handleSplashFileDrop(List<File> droppedFiles) async {
    if (!_isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected to device.')),
        );
      }
      return;
    }

    final validPngFiles = droppedFiles.where((file) => file.path.toLowerCase().endsWith('.png')).toList();
    if (validPngFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid PNG files found.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isUploadingTemplate = true; // TODO: Create separate state for splash screens
      });
    }

    try {
      for (final droppedFile in validPngFiles) {
        await _deviceManager.uploadSplashFile(
          pngFile: droppedFile,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Splash screen uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingTemplate = false;
        });
      }
    }
  }

  void _disconnect() {
    _deviceManager.disconnect();
    _connectionCheckerTimer?.cancel();
    setState(() {
      _isConnected = false;
      _ipAddress = '';
      _errorMessage = null;
    });
  }

  void _startConnectionChecker() {
    _connectionCheckerTimer?.cancel();
    _connectionCheckerTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final alive = await _deviceManager.isConnectionAlive();
      if (!alive && _isConnected) {
        setState(() {
          _isConnected = false;
          _errorMessage = 'Lost connection to device.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _DashboardDropCard(
            title: _isUploadingTemplate ? 'Uploading...' : 'Templates',
            icon: _isUploadingTemplate ? null : Icons.view_list_outlined,
            dropPath: '/templates',
            onFileDropped: (path, droppedFile) => _handleTemplateFileDrop(droppedFile), // <-- wrapped in [ ]
            showSpinner: _isUploadingTemplate,
          ),
          const SizedBox(height: 24),
          _DashboardDropCard(
            title: 'Splash Screens',
            icon: Icons.power_settings_new_outlined,
            dropPath: '/splash',
            onFileDropped: (path, droppedFile) => _handleSplashFileDrop(droppedFile),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1,        
                ),
              ),
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
                              foregroundColor: Colors.grey.shade700,
                              backgroundColor: Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
                                if (states.contains(WidgetState.focused)) {
                                  return Colors.white; // Background when focused
                                } else if (states.contains(WidgetState.hovered)) {
                                  return Colors.white; // Background when focused
                                }
                                  return Colors.white; // Background when focused
                              }),
                              labelText: 'Device IP',
                              hoverColor: Colors.grey[50],
                              floatingLabelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
                              ),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _ipAddress = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isConnecting ? null : _connectToDevice,
                            icon: _isConnecting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              backgroundColor: Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
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
  final IconData? icon;
  final String dropPath;
  final void Function(String path, List<File> droppedFiles) onFileDropped;
  final bool showSpinner;

  const _DashboardDropCard({
    required this.title,
    required this.icon,
    required this.dropPath,
    required this.onFileDropped,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
      return DragTarget<List<FileSystemEntity>>(
      onAcceptWithDetails: (DragTargetDetails<List<FileSystemEntity>> details) {
        final droppedEntities = details.data;
        final files = droppedEntities.whereType<File>().toList();
        if (files.isNotEmpty) {
          onFileDropped(dropPath, files); // Pass a List<File>
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return InkWell(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHighlighted ? Colors.grey.shade700 : Colors.grey.shade400,
                width: 1,
                style: BorderStyle.solid, 
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showSpinner)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(color: Colors.grey[700], strokeWidth: 3),
                  )
                else if (icon != null)
                  Icon(icon, size: 40, color: Colors.black54),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag files here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
