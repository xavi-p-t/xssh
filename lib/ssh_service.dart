import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:xssh/portRules.dart';

class SshService {
  SSHClient? _client;
  SSHSocket? _socket;

  final List<ServerSocket> _localServers = [];

  bool get isConnected => _client != null;

  Future<void> connect({
  required String host,
  required int port,
  required String username,
  required String privateKeyPath,
  required List<PortRule> rules,
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

    // --- INICIO LÓGICA DE TÚNELES (PORT FORWARDING) ---
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
          // 1. Abrimos el puerto en nuestro propio dispositivo
          final localServer = await ServerSocket.bind('127.0.0.1', localPort);
          _localServers.add(localServer); // Lo guardamos para poder cerrarlo luego
          
          onLog('[info] Tunnel opened: 127.0.0.1:$localPort -> $destHost:$destPort (${rule.name})');

          // 2. Escuchamos el tráfico que nos llega a ese puerto local
          localServer.listen((Socket localSocket) async {
            try {
              // 3. Le pedimos al servidor SSH que nos abra un canal hacia el destino
              final forward = await _client!.forwardLocal(destHost, destPort);
              
              // 4. Conectamos los cables de ida y vuelta
              forward.stream.cast<List<int>>().pipe(localSocket).catchError((_) {});
              localSocket.cast<List<int>>().pipe(forward.sink).catchError((_) {});
            } catch (e) {
              onLog('[error] Tunnel traffic error (${rule.name}): $e');
              localSocket.destroy();
            }
          });
        } catch (e) {
          // Error típico: el puerto local ya está ocupado por otra app
          onLog('[error] Failed to bind local port $localPort (${rule.name}): $e');
        }
      }
      // --- FIN LÓGICA DE TÚNELES ---

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
