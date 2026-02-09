import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SshService {
  SSHClient? _client;
  SSHSocket? _socket;

  bool get isConnected => _client != null;

  Future<void> connect({
  required String host,
  required int port,
  required String username,
  required String privateKeyPath,
  required void Function(String) onLog,
}) async {
  try {
    onLog('[info] Connecting to $username@$host:$port');

    _socket = await SSHSocket.connect(host, port);
    onLog('[info] TCP socket opened');

    final keyText = await File(privateKeyPath).readAsString();

    _client = SSHClient(
      _socket!,
      username: username,
      identities: [
        ...SSHKeyPair.fromPem(keyText),
      ],
    );

    onLog('[success] Connected!');
  } catch (e) {
    onLog('[error] $e');
    disconnect(onLog: onLog);
  }
}


  Future<void> disconnect({required void Function(String) onLog}) async {
    onLog('[info] Disconnecting...');
    _client?.close();
    _socket?.close();
    _client = null;
    _socket = null;
    onLog('[info] Disconnected');
  }

}
