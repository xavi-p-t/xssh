import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xssh/ssh_service.dart';
import 'package:xssh/SaveServer.dart';
import 'package:xssh/inputPers.dart';
import 'package:xssh/portRules.dart';

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

  // Aquí luego meteremos SshService, de momento solo print
  bool isConnecting = false;
  late TextEditingController privateKeyController;
  late TextEditingController hostController;
  late TextEditingController userController;
  late TextEditingController portController;


  final ssh = SshService();

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

  void saveConnection() {
    String name = user;
    String server = host;
    int ports = port;
    String? key = privateKeyPath;
    

    if (name.isEmpty || server.isEmpty || port == 0) {
        
       return;
     }

    

    final newUser = UserData(name: name, server: server, port: port, key: key,rules: List.from(rules),);

    final index = userDataList.indexWhere
      ( (u) => u.name == newUser.name && u.server == newUser.server, 
    ); 
    
    if (index != -1) { 
      userDataList[index] = newUser; } 
    else { 
      userDataList.add(newUser); 
    }

    Storage.saveUserData(userDataList);
    _loadUserData();
   
  }

  void removeConnection(int index) {
    userDataList.removeAt(index);
    Storage.saveUserData(userDataList);
    _loadUserData();
  }

  void onSelectConnection(UserData data) {
  setState(() {
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


  Future<void> onActivatePressed() async {
  if (host.isEmpty || user.isEmpty || privateKeyPath == null) {
    addLog('[error] Missing data');
    return;
  }

  setState(() => isConnecting = true);

  await ssh.connect(
    host: host,
    port: port,
    username: user,
    privateKeyPath: privateKeyPath!,
    onLog: addLog,
  );

  setState(() => isConnecting = false);
}

Future<void> onDeactivatePressed() async {
  await ssh.disconnect(onLog: addLog);
}



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Escala basada en el ancho de la ventana
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
                      saveConnection: saveConnection,
                      userDataList: userDataList,
                      removeConnection: removeConnection,
                      onSelectConnection: onSelectConnection,
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
                              isConnecting: isConnecting,
                              logs: logs,
                              rules: rules,
                              onAddRule: addRule,
                              onRemoveRule: removeRule,
                            ),
                          ),
                          _BottomBar(
                            onDeactivate: onDeactivatePressed,
                          ),
                        ],
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
  final VoidCallback saveConnection;
  final void Function(int) removeConnection;
  final void Function(UserData) onSelectConnection;

  const _LeftPanel({
    super.key,
    required this.saveConnection,
    required this.userDataList,
    required this.removeConnection,
    required this.onSelectConnection,
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
                  onPressed: saveConnection,
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
                return StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (context) => setState(() => hovering = true),
                      onExit: (context) => setState(() => hovering = false),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle:Text(user.server),
                        leading: const Icon(Icons.cloud),
                        trailing: hovering
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => removeConnection(index),
                              )
                            : null,
                        selected: index == 0,
                        onTap: () {
                          onSelectConnection(user);
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
          color: const Color.fromARGB(82, 188, 186, 186),        // Fondo oscuro
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Colors.grey.shade700),
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
                    //color: Colors.white,
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
                    //style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
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
                    //style: TextStyle(color: Colors.white70),
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
                    //style: TextStyle(color: Colors.white70),
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
                    //style: TextStyle(color: Colors.white70),
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
                  icon: const Icon(Icons.folder_open, color: Colors.white70),
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







class _LogOutput extends StatelessWidget {
  final List<String> logs;

  const _LogOutput({super.key, required this.logs});

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
                onPressed: () {},
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
                  logs.join("\n"),
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

  const _BottomBar({
    super.key,
    required this.onDeactivate,
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
          // ElevatedButton(onPressed: () {}, child: const Text('Activate')),
          // const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onDeactivate,
            child: const Text('Desactivate'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Refresh')),
          const Spacer(),
          const Text('Status:'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text('Connected', style: TextStyle(color: Colors.green.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
