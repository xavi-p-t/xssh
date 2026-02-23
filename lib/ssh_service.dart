import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:xssh/portRules.dart';

class SshService {
  SSHClient? _client;
  SSHSocket? _socket;

  final List<ServerSocket> _localServers = [];

  bool get isConnected => _client != null;
  
  getIsConnected(){
    return isConnected;
  }

  Future<void> connect({
  required String host,
  required int port,
  required String username,
  required String? privateKeyPath,
  required String? password,
  required List<PortRule> rules,
  required void Function(String) onLog,
}) async {
  try {
    onLog('[info] Connecting to $username@$host:$port');

    _socket = await SSHSocket.connect(host, port);
    onLog('[info] TCP socket opened');

    
    List<SSHKeyPair> identities = [];
      if (privateKeyPath != null && privateKeyPath.isNotEmpty) {
        final keyText = await File(privateKeyPath).readAsString();
        identities = SSHKeyPair.fromPem(keyText);
      }
    
    _client = SSHClient(
      _socket!,
      username: username,
      identities: identities,
      onPasswordRequest: password != null && password.isNotEmpty 
            ? () => password 
            : null,
    );

    onLog('[success] Connected!');

    // INICIO LOGICA DE TÚNELES
      for (var rule in rules) {
        
        if (rule.localPort.isEmpty || rule.destHost.isEmpty || rule.destPort.isEmpty) {
          onLog('[warning] Skipping incomplete rule: ${rule.name}');
          continue;
        }

        
        final int localPort = int.tryParse(rule.localPort) ?? 0;
        final int destPort = int.tryParse(rule.destPort) ?? 0;
        final String destHost = rule.destHost;

        if (localPort == 0 || destPort == 0) continue;

        try {
         
          final localServer = await ServerSocket.bind('127.0.0.1', localPort);
          _localServers.add(localServer); 
          
          onLog('[info] Tunnel opened: 127.0.0.1:$localPort -> $destHost:$destPort (${rule.name})');

          
          localServer.listen((Socket localSocket) async {
            try {
              
              final forward = await _client!.forwardLocal(destHost, destPort);
              
             
              forward.stream.cast<List<int>>().pipe(localSocket).catchError((_) {});
              localSocket.cast<List<int>>().pipe(forward.sink).catchError((_) {});
            } catch (e) {
              onLog('[error] Tunnel traffic error (${rule.name}): $e');
              localSocket.destroy();
            }
          });
          
        } catch (e) {
          
          onLog('[error] Failed to bind local port $localPort (${rule.name}): $e');
        }
      }
    
    
  } catch (e) {
    onLog('[error] $e');
    disconnect(onLog: onLog);
  }
}


  Future<void> disconnect({required void Function(String) onLog}) async {
    onLog('[info] Disconnecting...');

    for (var server in _localServers) {
      await server.close();
    }
    _localServers.clear();

    _client?.close();
    _socket?.close();
    _client = null;
    _socket = null;
    onLog('[info] Disconnected');
  }

}
