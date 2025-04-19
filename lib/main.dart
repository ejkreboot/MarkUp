import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MarkUpApp());
}

class MarkUpApp extends StatelessWidget {
  const MarkUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarkUp',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Text',
        scaffoldBackgroundColor: Colors.grey.shade100,
        colorScheme: const ColorScheme.light(),
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(fontWeight: FontWeight.w200),
          bodySmall: const TextStyle(fontWeight: FontWeight.w200),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w200),
          titleMedium: const TextStyle(fontWeight: FontWeight.w100),
        ),      
      ),
      home: const FileExplorerPage(),
    );
  }
}

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  String currentPath = Platform.environment['HOME'] ?? '/';
  List<FileSystemEntity> entries = [];
  FileSystemEntity? selectedFile;

  final List<String> deviceFolders = [
    '/templates',
    '/splash',
    '/archive',
    '/notes',
    '/',
  ];

  @override
  void initState() {
    super.initState();
    _loadDirectory(currentPath);
  }

Future<void> _loadDirectory(String path) async {
  final dir = Directory(path);
  if (await dir.exists()) {
    final children = dir.listSync();

    // Separate and sort folders and files
    final folders = <FileSystemEntity>[];
    final files = <FileSystemEntity>[];

    for (final entity in children) {
      if (FileSystemEntity.isDirectorySync(entity.path)) {
        if(!p.basename(entity.path).startsWith(".")) {
          folders.add(entity);
        }
      } else {
        if(!p.basename(entity.path).startsWith(".")) {
         files.add(entity);
        }
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


Widget _buildDeviceSidebar() {
  return Container(
    width: 200,
    color: Colors.grey.shade100,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDragTile('Templates', '/templates', Icons.folder_open),
        const SizedBox(height: 16),
        _buildDragTile('Splash Screens', '/splash', Icons.image_outlined),
        const Spacer(),
        const Divider(),
        const Text(
          "Connected to 192.168.1.2",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        ),
      ],
    ),
  );
}

Widget _buildDragTile(String label, String targetPath, IconData icon) {
  return DragTarget<FileSystemEntity>(
    onAcceptWithDetails: (details) {
      final file = details.data; // <-- Extract the actual file from DragTargetDetails
      _moveFileToTarget(file, targetPath);
    },
    builder: (context, candidateData, rejectedData) {
      final isHovered = candidateData.isNotEmpty;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isHovered ? Colors.blue : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      );
    },
  );
}

void _moveFileToTarget(FileSystemEntity file, String targetPath) {
  // TODO: Implement the move/copy logic
  print('Would move ${file.path} to $targetPath');
}

Widget _buildFileList() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
    child: Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text('File Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 1,
                child: Text('Modified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // File List
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.grey.shade300,
              height: 1,
              thickness: 0.5,
              indent: 0,
              endIndent: 0,
            ),
            itemBuilder: (context, index) {
              final entity = entries[index];
              final path = entity.path;
              final name = p.basename(path);
              final isUpEntry = p.basename(entity.path) == '..';
              if (isUpEntry) {
                return InkWell(
                  onTap: () => _loadDirectory(Directory(currentPath).parent.path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 20),
                              SizedBox(width: 8),
                              Text('..', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                            ],
                          ),
                        ),
                        Expanded(flex: 1, child: SizedBox.shrink()),
                      ],
                    ),
                  ),
                );
              }

              final isDir = FileSystemEntity.isDirectorySync(path);
              final isSvg = path.toLowerCase().endsWith('.svg');
              DateTime? modified;

              try {
                modified = File(path).lastModifiedSync();
              } catch (_) {}

              return InkWell(
                onTap: () {
                  if (isDir) {
                    _loadDirectory(path);
                  } else {
                    setState(() => selectedFile = entity);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: isDir
                                  ? const Icon(Icons.folder_outlined, size: 20)
                                  : isSvg
                                      ? SvgPicture.file(File(path), width: 20, height: 20)
                                      : const Icon(Icons.insert_drive_file_outlined, size: 20),
                            ),
                            Flexible(
                              child: Text(name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: modified != null
                            ? Text(
                                '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}


  Widget _buildPreviewPanel() {
    if (selectedFile == null || selectedFile is Directory) {
      return const Center(child: Text('Select a file to preview'));
    }

    final file = selectedFile!;
    final name = p.basename(file.path);
    final size = File(file.path).lengthSync();
    final isSvg = file.path.toLowerCase().endsWith('.svg');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Type: ${isSvg ? 'SVG' : 'File'}'),
              Text('Size: $size bytes'),
              const SizedBox(height: 16),
              if (isSvg)
                SvgPicture.file(File(file.path), width: 240, height: 320)
              else
                const Center(child: Icon(Icons.insert_drive_file_outlined, size: 100)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () => setState(() => selectedFile = null),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentPath),
      ),
      body: Row(
        children: [
          _buildDeviceSidebar(),
          const VerticalDivider(width: 1),
          Expanded(flex: 2, child: _buildFileList()),
          const VerticalDivider(width: 1),
          SizedBox(width: 320, child: _buildPreviewPanel()),
        ],
      ),
    );
  }
}
