import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class FileList extends StatefulWidget {
  final List<FileSystemEntity> entries;
  final String currentPath;
  final void Function(String path) onDirectoryTap;
  final void Function(List<FileSystemEntity> selectedFiles) onSelectionChanged;

  const FileList({
    super.key,
    required this.entries,
    required this.currentPath,
    required this.onDirectoryTap,
    required this.onSelectionChanged
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  Set<FileSystemEntity> selectedFiles = {};
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "   ${widget.currentPath}",   // <-- ADDED widget.
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Modified',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.entries.length,   
              itemBuilder: (context, index) {
                final entity = widget.entries[index]; 
                final path = entity.path;
                final name = p.basename(path);
                final isUpEntry = name == '..';
                final isDir = FileSystemEntity.isDirectorySync(path);
                final isSelected = selectedFiles.contains(entity);

                DateTime? modified;
                if (isUpEntry) {
                  return _buildUpEntry(
                    context,
                    () => widget.onDirectoryTap(Directory(widget.currentPath).parent.path), 
                  );
                }

                try {
                  modified = File(path).lastModifiedSync();
                } catch (_) {}

                return Draggable<List<FileSystemEntity>>(  
                  data: selectedFiles.isNotEmpty
                      ? widget.entries.where((e) => selectedFiles.contains(e)).toList()
                      : [entity],
                  feedback: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.file_copy_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              selectedFiles.length > 1
                                  ? '${selectedFiles.length} files'
                                  : p.basename(path),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: _buildFileRow(context, entity, name, isDir, modified, index, isSelected), // <-- PASSES isSelected
                  ),
                  child: GestureDetector(
                  onTap: () {
                    if (isDir) {
                      widget.onDirectoryTap(path);
                      return;
                    }

                    setState(() {
                      selectedFiles.contains(entity)
                        ? selectedFiles.remove(entity)
                        : selectedFiles.add(entity);
                    });
                    widget.onSelectionChanged(selectedFiles.toList());
                  }, 
                   child: _buildFileRow(context, entity, name, isDir, modified, index, isSelected),  // <-- PASSES isSelected
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    FileSystemEntity entity,
    String name,
    bool isDir,
    DateTime? modified,
    int index,
    bool isSelected, 
  ) {
    return Container(
      width: double.infinity,
      color: isSelected
          ? Color.fromARGB(25, 25, 25, 25)
          : (index.isEven ? const Color.fromARGB(255, 252, 252, 252) : Colors.grey.shade100),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: isDir
                        ? const Icon(Icons.folder_outlined, size: 20, color: Colors.black87)
                        : const Icon(Icons.insert_drive_file_outlined, size: 20, color: Colors.black87),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300, minWidth: 300),
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w300),
                      ),
                    ),
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
  }

  Widget _buildUpEntry(BuildContext context, VoidCallback onTap) {
    return Container(
      color: const Color.fromARGB(255, 252, 252, 252),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Icon(Icons.arrow_upward, size: 20),
                  ),
                  Flexible(
                    child: Text(
                      '..',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
