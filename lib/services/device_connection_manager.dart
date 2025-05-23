import 'dart:io';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import '../models/templates_list.dart';
import 'ssh_utils.dart'; 
import 'dart:convert';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceConnectionManager {
  late dynamic _client; 
  late SSHSocket _socket;
  bool _isConnected = false;
  static const _passwordKey = 'remarkable_password';
  final _storage = FlutterSecureStorage(
    mOptions: const MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      useDataProtectionKeyChain: false,
    ),
  );

  bool get isConnected => _isConnected;

  Future<String?> getSavedPassword() async {
    final password = await _storage.read(key: _passwordKey);
    return password;
  }

  Future<void> savePassword(String password) async {
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<void> clearPassword() async {
    await _storage.delete(key: _passwordKey);
    // Debug check: was it really deleted?
    final test = await _storage.read(key: _passwordKey);
    debugPrint('Password after delete: $test'); // should be null
  }

  DeviceConnectionManager({dynamic testClient}) {
    if (testClient != null) {
      _client = testClient;
      _isConnected = true;
    }
  }

  Future<void> connect(String ip, String? password) async {
    _socket = await SSHSocket.connect(ip, 22).timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        throw TimeoutException('Connection to $ip timed out');
      },
    );
    _client = SSHClient(
      _socket,
      username: 'root',
      onPasswordRequest: () => password,
    );
    await _client.authenticated; // This awaits until authenticated or throws
    _isConnected = true;
  }

  void disconnect() {
    _client.close();
    _isConnected = false;
  }

  void _ensureConnected() {
    if (!_isConnected) throw Exception('Not connected');
  }

  Future<String> downloadFile(String remotePath) async {
    _ensureConnected();
    final sftp = await _client.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final fileLength = (await file.stat()).size ?? 0;
    final fileData = await file.readBytes(length: fileLength);
    await file.close();
    return utf8.decode(fileData);
  }

  Future<void> uploadFile(File localFile, String remotePath) async {
    _ensureConnected();

    // Check disk space
    final diskSpace = await getDiskSpace();
    final rootFreeSpace = diskSpace['/'];
    final homeFreeSpace = diskSpace['/home'];

    if (rootFreeSpace == null || homeFreeSpace == null) {
      throw Exception('Unable to determine free space on device.');
    }

    // Parse free space values
    final rootFreeMB = _parseFreeSpace(rootFreeSpace);
    final homeFreeMB = _parseFreeSpace(homeFreeSpace);

    // Ensure minimum free space
    if (rootFreeMB < 5.0 || homeFreeMB < 1024.0) {
      throw Exception('Insufficient free space on device to upload safely.');
    }

    // Proceed with file upload
    final sftp = await _client.sftp();
    final remoteFile = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
    );
    final bytes = await localFile.readAsBytes();
    await remoteFile.writeBytes(bytes);
    await remoteFile.close();
  }

  Future<void> uploadStringAsFile(String content, String remotePath) async {
    _ensureConnected();
    final sftp = await _client.sftp();
    final remoteFile = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
    );
    await remoteFile.writeBytes(Uint8List.fromList(content.codeUnits));
    await remoteFile.close();
  }

  Future<void> ensureTemplatesFolderExists() async {
    _ensureConnected();
    await sshExecuteCommand(_client, 'test -d /home/root/templates || mkdir -p /home/root/templates');
  }

  Future<void> ensureSplashFolderExists() async {
    _ensureConnected();
    await sshExecuteCommand(_client, 'test -d /home/root/splash || mkdir -p /home/root/splash');
  }

  Future<void> createTemplateSymlink(String filename) async {
    _ensureConnected();
    final sourcePath = '/home/root/templates/$filename';
    final destPath = '/usr/share/remarkable/templates/$filename';
    await sshExecuteCommand(_client, 'ln -sf "$sourcePath" "$destPath"');
  }

  Future<void> createSplashSymlink(String filename) async {
    _ensureConnected();
    final sourcePath = '/home/root/splash/$filename';
    final destPath = '/usr/share/remarkable/$filename';
    await sshExecuteCommand(_client, 'ln -sf "$sourcePath" "$destPath"');
  }

  Future<bool> isConnectionAlive() async {
    if (!_isConnected) return false;
    try {
      await sshExecuteCommand(_client, 'true');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remoteFileExists(String remotePath) async {
    _ensureConnected();
    try {
      await sshExecuteCommand(_client, 'test -f "$remotePath"');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> copyRemoteFile(String sourcePath, String destPath) async {
    _ensureConnected();
    await sshExecuteCommand(_client, 'cp "$sourcePath" "$destPath"');
  }

  Future<String> fetchTemplatesJson() async {
    return await downloadFile('/usr/share/remarkable/templates/templates.json');
  }

  String normalizeTemplateFilename(String filename) {
    if (filename.startsWith('P ')) return filename;
    return 'P $filename';
  }

  Future<void> uploadTemplateAndUpdateJson({
    required File localSvgFile,
    required String templateName,
    required String templateFilename,
    required String category,
  }) async {
    _ensureConnected();

    if (!localSvgFile.path.toLowerCase().endsWith('.svg')) {
      throw Exception('Only SVG files are supported.');
    }

    final rawFilename = localSvgFile.uri.pathSegments.last;
    final normalizedFilename = normalizeTemplateFilename(rawFilename);
    final strippedFilename = normalizedFilename.replaceAll('.svg', '');

    // Step 1: Download and parse templates.json
    final templatesJsonPath = '/usr/share/remarkable/templates/templates.json';
    final templatesJsonString = await downloadFile(templatesJsonPath);
    final templatesList = TemplatesList.fromJson(templatesJsonString);

    // Step 2: Check if the template already exists
    final templateExists = templatesList.templates.any((template) => template.filename == strippedFilename);
    if (templateExists) {
      throw Exception('Template already exists');
    }

    // Step 3: Proceed with upload
    await ensureTemplatesFolderExists();
    await uploadFile(localSvgFile, '/home/root/templates/$normalizedFilename');
    await createTemplateSymlink(normalizedFilename);

    // Step 4: Update templates.json
    final backupPath = '/usr/share/remarkable/templates/templates.json.bak';
    await _ensureBackupExists(templatesJsonPath, backupPath);
    await _updateTemplatesJson(
      templatesJsonPath: templatesJsonPath,
      templateName: templateName,
      templateFilename: strippedFilename,
      category: category,
    );
  }

  Future<void> uploadSplashFile({
    required File pngFile,
  }) async {
    _ensureConnected();

    if (!pngFile.path.toLowerCase().endsWith('.png')) {
      throw Exception('Only PNG files are supported for splash files.');
    }
    final baseFilename = pngFile.uri.pathSegments.last;
    await ensureSplashFolderExists();
    await uploadFile(pngFile, '/home/root/templates/$baseFilename');
    await createSplashSymlink(baseFilename);
  }

  Future<void> _ensureBackupExists(String templatesJsonPath, String backupPath) async {
    debugPrint('Checking if backup exists.');
    final backupExists = await remoteFileExists(backupPath);
    if (!backupExists) {
      debugPrint('Creating backup: $backupPath');
      await copyRemoteFile(templatesJsonPath, backupPath);
    } else {
      debugPrint('Backup already exists: $backupPath');
    }
  }

  String _safeJsonEncode(Object object) {
    return JsonEncoder.withIndent('  ').convert(object).replaceAllMapped(
      RegExp(r'[\u007F-\uFFFF]'),
      (match) {
        final c = match.group(0)!.codeUnitAt(0);
        return '\\u${c.toRadixString(16).padLeft(4, '0')}';
      },
    );
  }

  Future<void> _updateTemplatesJson({
    required String templatesJsonPath,
    required String templateName,
    required String templateFilename,
    required String category
  }) async {
    final templatesJsonString = await downloadFile(templatesJsonPath);
    final templatesList = TemplatesList.fromJson(templatesJsonString);

    templatesList.addTemplate(
      name: templateName,
      filename: templateFilename,
      category: category
    );

    final updatedJsonString = _safeJsonEncode(templatesList);
    await uploadStringAsFile(updatedJsonString, templatesJsonPath);
  }

  Future<Map<String, String>> getDiskSpace() async {
    _ensureConnected();
    final result = await sshExecuteCommand(_client, 'df -h / /home');
    final lines = result.stdout.toString().trim().split('\n');
    final data = <String, String>{};

    for (final line in lines.skip(1)) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 6) {
        final mountPoint = parts[5];
        final available = parts[3];
        data[mountPoint] = "$available (${parts[4]} used)";
      }
    }

    return data; // e.g., {'/': '11G', '/home': '500M'}
  }

  Future<void> restartXochitl() async {
    _ensureConnected();
    await sshExecuteCommand(_client, 'systemctl restart xochitl');
  }
  
  double _parseFreeSpace(String freeSpace) {
    final match = RegExp(r'(\d+(\.\d+)?)([KMG])').firstMatch(freeSpace);
    if (match == null) {
      throw Exception('Unable to parse free space: $freeSpace');
    }

    final value = double.parse(match.group(1)!);
    final unit = match.group(3);

    switch (unit) {
      case 'K':
        return value / 1024; // Convert KB to MB
      case 'M':
        return value; // Already in MB
      case 'G':
        return value * 1024; // Convert GB to MB
      default:
        throw Exception('Unknown unit in free space: $unit');
    }
  }
}
