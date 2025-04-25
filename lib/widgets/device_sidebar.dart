import 'package:flutter/material.dart';
import '../services/device_connection_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:markup/dialogs/password_dialog.dart';  // <-- Import your dialog function

class DeviceSidebar extends StatefulWidget {
  final DeviceConnectionManager deviceManager;
  final VoidCallback onConnected;

  const DeviceSidebar({super.key, required this.deviceManager, required this.onConnected});

  @override
  State<DeviceSidebar> createState() => _DeviceSidebarState();
}

class _DeviceSidebarState extends State<DeviceSidebar> {
  String _ipAddress = '';
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isUploadingTemplate = false;
  bool _isUploadingSplash = false; // New state for uploading splash screens
  String? _errorMessage;
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Timer? _connectionCheckerTimer;
  
  Future<void> _connectToDevice() async {
    bool retry = true;
    String? password;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    while (retry) {
      retry = false; 
      password = await widget.deviceManager.getSavedPassword();
      if (password == null) {
        if (!mounted) return;
        final result = await showPasswordDialog(context);
        if (!mounted) return;

        if (result != null) {
          if (result.rememberPassword) {
            await widget.deviceManager.savePassword(result.password);
          }
          password = result.password;
        } else {
          setState(() {
            _isConnecting = false;
          });
          return;
        }
      }

      try {
        await widget.deviceManager.connect(_ipAddress, password);
        setState(() {
          _isConnected = true;
          _startConnectionChecker();
        });
        widget.onConnected();
      } on TimeoutException catch (_) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection timed out. Verify device is awake and IP address correct.')),
          );
        });
      } catch (e) {
        setState(() {
          _isConnected = false;
        });
        await widget.deviceManager.clearPassword();
        password = null;
        retry = true; 
      } finally {
        if (!retry) {
          setState(() {
            _isConnecting = false;
          });
        }
      }
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

    final category = _categoryController.text.trim().isEmpty ? "User" : _categoryController.text.trim();

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

        await widget.deviceManager.uploadTemplateAndUpdateJson(
          localSvgFile: droppedFile,
          templateName: templateName,
          templateFilename: templateFilename,
          category: category
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
          SnackBar(content: Text('Upload failed: ${e.toString().replaceAll("Exception:", "")}')),
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
        _isUploadingSplash = false; // Use the new state
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
        _isUploadingSplash = true; // Use the new state
      });
    }

    try {
      for (final droppedFile in validPngFiles) {
        await widget.deviceManager.uploadSplashFile(
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
          SnackBar(content: Text('Upload failed: ${e.toString().replaceAll("Exception:", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingSplash = false; // Reset the new state
        });
      }
    }
  }

  void _disconnect() {
    widget.deviceManager.disconnect();
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
      final alive = await widget.deviceManager.isConnectionAlive();
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
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category'
            ),
          ),
          const SizedBox(height: 8),
          _DashboardDropCard(
            title: _isUploadingTemplate ? 'Uploading...' : 'Templates',
            icon: _isUploadingTemplate ? null : Icons.view_list_outlined,
            dropPath: '/templates',
            onFileDropped: (path, droppedFile) => _handleTemplateFileDrop(droppedFile), // <-- wrapped in [ ]
            showSpinner: _isUploadingTemplate,
          ),
          const SizedBox(height: 12),
          _DashboardDropCard(
            title: _isUploadingSplash ? 'Uploading...' : 'Splash Screens',
            icon: _isUploadingTemplate ? null : Icons.power_settings_new_outlined,
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
                          const Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
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
            padding: const EdgeInsets.symmetric(vertical: 18),
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
