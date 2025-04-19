import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class DeviceConnectionManager {
  late SSHClient _client;
  late SSHSocket _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect(String ip, String password) async {
    _socket = await SSHSocket.connect(ip, 22);
    _client = SSHClient(_socket,
      username: 'root',
      onPasswordRequest: () => password,
    );
    _isConnected = true;
  }

Future<void> disconnect() async {
  _client.close();
  _isConnected = false;
}

  Future<String> downloadFile(String remotePath) async {
    if (!_isConnected) throw Exception('Not connected');
    final sftp = await _client!.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);

    final fileLength = (await file.stat()).size ?? 0;
    final fileData = await file.readBytes(length: fileLength);
    await file.close();

    return String.fromCharCodes(fileData);
  }

  Future<void> uploadFile(File localFile, String remotePath) async {
    if (!_isConnected) throw Exception('Not connected');
    final sftp = await _client!.sftp();
    final remoteFile = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
    );
    final bytes = await localFile.readAsBytes();
    await remoteFile.writeBytes(bytes);
    await remoteFile.close();
  }
}
