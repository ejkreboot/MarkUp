import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

class SSHCommandResult {
  final String stdout;
  final String stderr;
  final int? exitCode;

  SSHCommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });
}

Future<SSHCommandResult> sshExecuteCommand(
  SSHClient client,
  String command,
) async {
  try {
    final session = await client.execute(command);

    final stdout = await session.stdout
        .transform(StreamTransformer.fromBind(utf8.decoder.bind))
        .join();

    final stderr = await session.stderr
        .transform(StreamTransformer.fromBind(utf8.decoder.bind))
        .join();

    final exitCode = session.exitCode;
    await session.done;

    if (stderr.isNotEmpty) {
      throw Exception('SSH command error: $stderr');
    }

    return SSHCommandResult(
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
    );
  } catch (e) {
    throw Exception('SSH command failed: $e');
  }
}
