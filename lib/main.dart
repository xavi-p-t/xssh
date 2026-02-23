import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xssh/ssh_service.dart';
import 'package:xssh/SaveServer.dart';
import 'package:xssh/inputPers.dart';
import 'package:xssh/portRules.dart';
import 'package:xssh/OllamaChatPannel.dart';

void main() {
  runApp(const SshTunelApp());
}

class SshTunelApp extends StatelessWidget {
  const SshTunelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'XSSH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 212, 64, 96)),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Campos del formulario
  String host = '';
  String user = '';
  int port = 0;
  String? privateKeyPath;

  
  bool isConnecting = false;
  bool connected = false;

  Map<int, SshService> activeServices = {};

  Set<int> connectedProfiles = {};
  Set<int> connectingProfiles = {};


  late TextEditingController privateKeyController;
  late TextEditingController hostController;
  late TextEditingController userController;
  late TextEditingController portController;

  int? selectedIndex;


 
  List<String> logs = [];
  List<UserData> userDataList = [];
  List<PortRule> rules = [];

  void addRule() {
    setState(() {
      rules.add(PortRule());
    });
  } 

  void removeRule(int index) {
    setState(() {
      rules.removeAt(index);
    });
  }



  void addLog(String msg) {
    setState(() {
      logs.add(msg);
    });
  }


  @override
  void initState() {
    super.initState();
    privateKeyController = TextEditingController();
    hostController = TextEditingController();
    userController = TextEditingController();
    portController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() async {
    userDataList = await Storage.loadUserData();
    setState(() {});
  }

  void createNewConnection() {
    final newConnection = UserData(
      name: 'Sin nombre', 
      server: '', 
      port: 0, 
      key: null, 
      rules: []
    );

    setState(() {
      userDataList.add(newConnection);
      
      selectedIndex = userDataList.length - 1; 
    });
    
    Storage.saveUserData(userDataList);
    onSelectConnection(newConnection, selectedIndex!);
  }

  void refreshConnection(){
    if (selectedIndex == null){
      return;
    }

    setState(() {
      final savedData = userDataList[selectedIndex!];

      onSelectConnection(savedData, selectedIndex!);
    });
  }

  void saveConnection() {
    if (selectedIndex == null) return; 

    
    String name = userController.text.isNotEmpty ? userController.text : 'Sin nombre';
    String server = hostController.text;
    int ports = int.tryParse(portController.text) ?? 22;
    String? key = privateKeyPath;

    final updatedUser = UserData(
      name: name, 
      server: server, 
      port: ports, 
      key: key, 
      rules: List.from(rules),
    );

    setState(() {
      
      userDataList[selectedIndex!] = updatedUser;
      
      
      user = name;
      host = server;
      port = ports;
    });

    Storage.saveUserData(userDataList);
    addLog('[info] Configuración guardada correctamente.');
  }

  void removeConnection(int index) {
    setState(() {
      userDataList.removeAt(index);
      
      if (selectedIndex == index) {
        selectedIndex = null;
        hostController.clear();
        userController.clear();
        portController.clear();
        privateKeyController.clear();
        rules.clear();
      } else if (selectedIndex != null && index < selectedIndex!) {
        
        selectedIndex = selectedIndex! - 1;
      }
    });
    Storage.saveUserData(userDataList);
  }

  void removeConnectionByName(String name) {
    
    final index = userDataList.indexWhere(
      (u) => u.name.toLowerCase().trim() == name.toLowerCase().trim()
    );
    
    if (index != -1) {
      removeConnection(index); 
      addLog('[info] Ollama ha borrado la conexión: $name');
    } else {
      addLog('[warning] Ollama intentó borrar "$name" pero no existe en la lista.');
    }
  }

  void onSelectConnection(UserData data, int index) {
      setState(() {
        selectedIndex = index; 
        
        host = data.server;
        user = data.name;
        port = data.port;
        privateKeyPath = data.key;

        hostController.text = data.server; 
        userController.text = data.name; 
        portController.text = data.port.toString();
        privateKeyController.text = data.key ?? '';
        rules = List.from(data.rules);
      });
    }


  void onHostChanged(String value) => setState(() => host = value);
  void onUserChanged(String value) => setState(() => user = value);
  void onPortChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      setState(() => port = parsed);
    }
  }

  void onPrivateKeySelected(String path) {
    setState(() {
      privateKeyPath = path;
      privateKeyController.text = path;
    });
  }

  // Future<void> onActivatePressed() async {
    
  //   if (host.isEmpty || user.isEmpty) {
  //     addLog('[error] Missing data (Host or User)');
  //     return;
  //   }

  //   //POP-UP DE CONTRASEÑA 
  //   final String? password = await showDialog<String>(
  //     context: context,
  //     barrierDismissible: false, 
  //     builder: (BuildContext dialogContext) {
  //       final pwdController = TextEditingController();
        
  //       return AlertDialog(
  //         backgroundColor: const Color.fromARGB(255, 50, 50, 50), 
  //         title: const Text(
  //           'Authentication Required', 
  //           style: TextStyle(color: Colors.white, fontSize: 18)
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min, 
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Host: $host', style: const TextStyle(color: Colors.white70)),
  //             Text('User: $user', style: const TextStyle(color: Colors.white70)),
  //             Text('Port: $port', style: const TextStyle(color: Colors.white70)),
  //             const SizedBox(height: 20),
  //             TextField(
  //               controller: pwdController,
  //               obscureText: true, 
  //               style: const TextStyle(color: Colors.white),
  //               decoration: const InputDecoration(
  //                 labelText: 'Password',
  //                 labelStyle: TextStyle(color: Colors.white54),
  //                 enabledBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: Colors.white24)
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: Color.fromARGB(255, 212, 64, 96))
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(dialogContext).pop(null), 
  //             child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.of(dialogContext).pop(pwdController.text), 
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color.fromARGB(255, 212, 64, 96),
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('Accept'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   //COMPROBAMOS QUÉ HA HECHO EL USUARIO
  //   if (password == null) {
  //     addLog('[info] Connection cancelled by user.');
  //     return; 
  //   }

  //   if (selectedIndex == null) return;
  //   final int activeIndex = selectedIndex!;

    
  //   setState(() => connectingProfiles.add(activeIndex));

    
  //   if (!activeServices.containsKey(activeIndex)) {
  //     activeServices[activeIndex] = SshService();
  //   }

  //   //CONECTAMOS
  //   await activeServices[activeIndex]!.connect(
  //     host: host,
  //     port: port,
  //     username: user,
  //     privateKeyPath: privateKeyPath,
  //     password: password, 
  //     rules: rules, 
  //     onLog: addLog,
  //   );

    
  //   setState(() {
  //     connectingProfiles.remove(activeIndex);
      
  //     if (activeServices[activeIndex]!.getIsConnected()) {
  //       connectedProfiles.add(activeIndex);
  //     }
  //   });
  // }

  // --- NUEVA FUNCIÓN QUE SOLO SE EJECUTA SI SE LE LLAMA ---
  Future<String?> promptForPassword() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final pwdController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 50, 50, 50),
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Host: $host', style: const TextStyle(color: Colors.white70)),
              Text('User: $user', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(
                controller: pwdController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password / Passphrase',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 212, 64, 96))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(pwdController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 212, 64, 96),
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  // --- TU FUNCIÓN ACTIVATE REDUCIDA Y LIMPIA ---
  Future<void> onActivatePressed() async {
    if (selectedIndex == null) return;
    final int activeIndex = selectedIndex!;

    if (host.isEmpty || user.isEmpty) {
      addLog('[error] Missing data (Host or User)');
      return;
    }

    // 1. Empezamos a conectar directamente (la rueda gira)
    setState(() => connectingProfiles.add(activeIndex));

    if (!activeServices.containsKey(activeIndex)) {
      activeServices[activeIndex] = SshService();
    }

    try {
      await activeServices[activeIndex]!.connect(
        host: host,
        port: port,
        username: user,
        privateKeyPath: privateKeyPath,
        
        // 2. LE PASAMOS LA FUNCIÓN (SIN EJECUTARLA) PARA QUE EL SSH LA USE SI LA NECESITA
        onPasswordRequestUI: promptForPassword, 
        
        rules: rules,
        onLog: addLog,
      );

      // Si termina todo bien, lo marcamos conectado
      setState(() {
        if (activeServices[activeIndex]!.getIsConnected()) {
          connectedProfiles.add(activeIndex);
        }
      });
    } catch (e) {
      addLog('[error] Connection failed: $e');
    } finally {
      setState(() => connectingProfiles.remove(activeIndex));
    }
  }

  Future<void> onDeactivatePressed() async {
      if (selectedIndex == null) return;
      final int activeIndex = selectedIndex!;


      if (activeServices.containsKey(activeIndex)) {
        await activeServices[activeIndex]!.disconnect(onLog: addLog);
      }
      

      setState(() {
        connectedProfiles.remove(activeIndex);
      });
  }

  //FUNCION ACTIVAR PARA LA IA
  Future<void> activateConnectionByName(String name) async {
   
    final index = userDataList.indexWhere(
      (u) => u.name.toLowerCase().trim() == name.toLowerCase().trim()
    );
    
    if (index != -1) {
      
      onSelectConnection(userDataList[index], index);
      addLog('[info] La IA está intentando conectar: $name');
      
      
      await onActivatePressed();
    } else {
      addLog('[warning] La IA intentó conectar "$name" pero no existe en la lista.');
    }
  }
  //FUNCION DESACTIVAR PARA LA IA
  Future<void> deactivateConnectionByName(String name) async {
    final index = userDataList.indexWhere(
      (u) => u.name.toLowerCase().trim() == name.toLowerCase().trim()
    );
    
    if (index != -1) {
      
      if (activeServices.containsKey(index)) {
        await activeServices[index]!.disconnect(onLog: addLog);
        setState(() {
          connectedProfiles.remove(index);
        });
        addLog('[info] La IA ha apagado la conexión: $name');
      } else {
        addLog('[info] La IA intentó apagar "$name" pero ya estaba desconectado.');
      }
    } else {
      addLog('[warning] La IA intentó desconectar "$name" pero no existe.');
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isCurrentConnecting = selectedIndex != null && connectingProfiles.contains(selectedIndex);
    final bool isCurrentConnected = selectedIndex != null && connectedProfiles.contains(selectedIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        
        final scale = (constraints.maxWidth / 1400).clamp(0.5, 1.0);

        return FittedBox(
          alignment: Alignment.topLeft,
          fit: BoxFit.none,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: constraints.maxWidth / scale,
              height: constraints.maxHeight / scale,
              child: Scaffold(
                body: Row(
                  children: [
                    _LeftPanel(
                      onAddConnection: createNewConnection,
                      userDataList: userDataList,
                      removeConnection: removeConnection,
                      onSelectConnection: onSelectConnection,
                      connectedProfiles: connectedProfiles,
                      selectedIndex: selectedIndex,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _RightPanel(
                              host: host,
                              user: user,
                              port: port,
                              privateKeyPath: privateKeyPath,
                              privateKeyController: privateKeyController,
                              hostController: hostController,
                              userController: userController,
                              portController: portController,
                              onHostChanged: onHostChanged,
                              onUserChanged: onUserChanged,
                              onPortChanged: onPortChanged,
                              onPrivateKeySelected: onPrivateKeySelected,
                              onActivate: onActivatePressed,
                              isConnecting: isCurrentConnecting,
                              logs: logs,
                              rules: rules,
                              onAddRule: addRule,
                              onRemoveRule: removeRule,
                            ),
                          ),
                          _BottomBar(
                            onDeactivate: onDeactivatePressed,
                            isConnecting:isCurrentConnected,
                            onSave: saveConnection,
                            onRefresh:refreshConnection,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),

                    SizedBox(
                      width: 320,
                      child: OllamaChatPanel(
                        onCreateConnection: createNewConnection, 
                        onDeleteConnection: removeConnectionByName,
                        onConnectConnection: activateConnectionByName,   
                        onDisconnectConnection: deactivateConnectionByName,
                      ),  
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}


class _LeftPanel extends StatelessWidget {
  final List<UserData> userDataList;
  final VoidCallback onAddConnection;
  final void Function(int) removeConnection;
  final void Function(UserData, int) onSelectConnection;
  final Set<int> connectedProfiles;
  final int? selectedIndex;

  const _LeftPanel({
    super.key,
    required this.onAddConnection,
    required this.userDataList,
    required this.removeConnection,
    required this.onSelectConnection,
    required this.connectedProfiles,
    required this.selectedIndex,
    });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SSH Configurations',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                    //boton añadir
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onAddConnection,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount:userDataList.length,
              itemBuilder: (context, index) {
                bool hovering = false;
                final user = userDataList[index];
                final bool isThisConnected = connectedProfiles.contains(index);
                return StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (context) => setState(() => hovering = true),
                      onExit: (context) => setState(() => hovering = false),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle:Text(user.server),
                        leading:  Icon(Icons.circle, size: 10, color: isThisConnected ? Colors.green.shade700:Colors.red.shade700),
                        trailing: hovering
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => removeConnection(index),
                              )
                            : null,
                        selected: index == 0,
                        onTap: () {
                          onSelectConnection(user,index);
                        },
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  final String host;
  final String user;
  final int port;
  final String? privateKeyPath;
  final ValueChanged<String> onHostChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onPortChanged;
  final ValueChanged<String> onPrivateKeySelected;
  final VoidCallback onActivate;
  final bool isConnecting;
  final TextEditingController privateKeyController;
  final TextEditingController hostController;
  final TextEditingController userController;
  final TextEditingController portController;
  final List<String> logs;
  final List<PortRule> rules;
  final void Function() onAddRule;
  final void Function(int) onRemoveRule;



  const _RightPanel({
    super.key,
    required this.host,
    required this.user,
    required this.port,
    required this.privateKeyPath,
    required this.onHostChanged,
    required this.onUserChanged,
    required this.onPortChanged,
    required this.onPrivateKeySelected,
    required this.onActivate,
    required this.isConnecting,
    required this.privateKeyController,
    required this.hostController,
    required this.userController,
    required this.portController,
    required this.logs,
    required this.rules,
    required this.onAddRule,
    required this.onRemoveRule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConnectionForm(
          host: host,
          user: user,
          port: port,
          privateKeyPath: privateKeyPath,
          privateKeyController: privateKeyController,
          hostController: hostController,
          userController: userController,
          portController: portController,
          onHostChanged: onHostChanged,
          onUserChanged: onUserChanged,
          onPortChanged: onPortChanged,
          onPrivateKeySelected: onPrivateKeySelected,
          onActivate: onActivate,
          isConnecting: isConnecting,
        ),
        
        Expanded(
          flex: 2,
          child: PortRules(
            rules: rules,
            onAddRule: onAddRule,
            onRemoveRule: onRemoveRule,
          ),
        ),
        Expanded(
          flex: 1,
          child: _LogOutput(logs: logs),
        ),

      ],
    );
  }
}


class _ConnectionForm extends StatelessWidget {
  final String host;
  final String user;
  final int port;
  final String? privateKeyPath;
  final TextEditingController privateKeyController;
  final TextEditingController hostController;
  final TextEditingController userController;
  final TextEditingController portController;
  final ValueChanged<String> onHostChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onPortChanged;
  final ValueChanged<String> onPrivateKeySelected;
  final VoidCallback onActivate;
  final bool isConnecting;

  const _ConnectionForm({
  super.key,
  required this.host,
  required this.user,
  required this.port,
  required this.privateKeyPath,
  required this.privateKeyController,
  required this.hostController,
  required this.userController,
  required this.portController,
  required this.onHostChanged,
  required this.onUserChanged,
  required this.onPortChanged,
  required this.onPrivateKeySelected,
  required this.onActivate,
  required this.isConnecting,
});


  Future<void> _pickPrivateKey(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select private key',
    type: FileType.any,
  );

  if (result != null && result.files.single.path != null) {
    onPrivateKeySelected(result.files.single.path!);
  }
}


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(82, 188, 186, 186),     
          borderRadius: BorderRadius.circular(12),
         
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONNECTION DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    
                  ),
                ),
                ElevatedButton(
                  onPressed: isConnecting ? null : onActivate,
                  child: Text(isConnecting ? 'Connecting...' : 'Activate'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // HOST
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'HOST',
                    
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: hostController,
                    decoration: darkInput('Enter host'),
                    onChanged: onHostChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // USER
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'USER',
                    
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: userController,
                    decoration: darkInput('Enter user'),
                    onChanged: onUserChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PORT
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'PORT',
                    
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: portController,
                    decoration: darkInput('22'),
                    keyboardType: TextInputType.number,
                    onChanged: onPortChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PRIVATE KEY
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'KEY',
                    
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: privateKeyController,
                    readOnly: true,
                    decoration: darkInput('Select key'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Color.fromARGB(255, 0, 0, 0)),
                  onPressed: () => _pickPrivateKey(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  checkColor: Colors.black,
                  activeColor: Colors.white,
                ),
                const Text('Reconnect automatically', style: TextStyle(color: Color.fromARGB(179, 0, 0, 0))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







class _LogOutput extends StatefulWidget {
  final List<String> logs;

  const _LogOutput({super.key, required this.logs});

  @override
  State<_LogOutput> createState() => _LogOutputState();
}

class _LogOutputState extends State<_LogOutput> {
  void cleanLog() {
    setState(() {
      widget.logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SSH Output',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: cleanLog,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text(
                  widget.logs.join("\n"),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onDeactivate;
  final bool isConnecting;
  final VoidCallback onSave;
  final VoidCallback onRefresh;

  const _BottomBar({
    super.key,
    required this.onDeactivate,
    required this.isConnecting,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          
          ElevatedButton(
            onPressed: onDeactivate,
            child: const Text('Deactivate'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 212, 64, 96),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
          const Spacer(),
          const Text('Status:'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnecting ? Colors.green.shade100 : Colors.red.shade100 ,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: isConnecting ? Colors.green.shade700:Colors.red.shade700),
                const SizedBox(width: 6),
                Text(isConnecting ?'Connected':'Disconnected', style: TextStyle(color: isConnecting ? Colors.green.shade800:Colors.red.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
