import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../widgets/device_sidebar.dart';
import '../widgets/file_list.dart';
import '../widgets/preview_panel.dart';

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  String currentPath = Platform.environment['HOME'] ?? '/';
  List<FileSystemEntity> entries = [];
  FileSystemEntity? selectedFile;

  @override
  void initState() {
    super.initState();
    _loadDirectory(currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      final children = dir.listSync();

      final folders = <FileSystemEntity>[];
      final files = <FileSystemEntity>[];

      for (final entity in children) {
        final notAllowed = (! FileSystemEntity.isDirectorySync(entity.path) &&
                            ! entity.path.toLowerCase().endsWith('.svg') && 
                            ! entity.path.toLowerCase().endsWith('.png')) |
                            p.basename(entity.path).startsWith('.');

        if (notAllowed) {
          continue;
        }

        if (FileSystemEntity.isDirectorySync(entity.path)) {
          folders.add(entity);
        } else {
          files.add(entity);
        }
      }

      folders.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      files.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));

      setState(() {
        currentPath = path;
        entries = [];

        if (Directory(path).parent.path != path) {
          entries.add(File('..'));
        }

        entries.addAll(folders);
        entries.addAll(files);
        selectedFile = null;
      });
    }
  }

  void _handleDirectoryTap(String path) {
    _loadDirectory(path);
  }

  void _handleFileTap(FileSystemEntity file) {
    setState(() {
      selectedFile = file;
    });
  }

  void _handleClosePreview() {
    setState(() {
      selectedFile = null;
    });
  }

  void _handleFileDropped(String targetPath, File file) {
    print('Dropped file: ${file.path} onto $targetPath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DeviceSidebar(
            onCardTap: _handleDirectoryTap,
            onFileDropped: _handleFileDropped,
          ),
          const VerticalDivider(width: 1, color: Color.fromARGB(255, 205, 205, 205)),
          Expanded(
            flex: 2,
            child: FileList(
              entries: entries,
              currentPath: currentPath,
              onDirectoryTap: _handleDirectoryTap,
              onFileTap: _handleFileTap,
            ),
          ),
          const VerticalDivider(width: 1, color: Color.fromARGB(255, 205, 205, 205)),
          SizedBox(
            width: 320,
            child: PreviewPanel(
              selectedFile: selectedFile,
              onClose: _handleClosePreview,
            ),
          ),
        ],
      ),
    );
  }
}
