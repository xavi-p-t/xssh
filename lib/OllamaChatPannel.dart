import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OllamaChatPanel extends StatefulWidget {
  final VoidCallback onCreateConnection;
  final Function(String) onDeleteConnection;
  final Function(String) onConnectConnection;  
  final Function(String) onDisconnectConnection;

  const OllamaChatPanel({
    super.key,
    required this.onCreateConnection,
    required this.onDeleteConnection,
    required this.onConnectConnection,  
    required this.onDisconnectConnection,
  });

  @override
  State<OllamaChatPanel> createState() => _OllamaChatPanelState();
}

class _OllamaChatPanelState extends State<OllamaChatPanel> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [
    {'role': 'assistant', 'content': '¡Hola! Soy la IA. Puedo ayudarte con dudas de SSH o gestionar tus conexiones. Pídeme que cree o borre alguna.'}
  ];

  bool _isLoading = false;

  // --- TOOLS DEL FUNCTION CALL ---
  final List<Map<String, dynamic>> _tools = [
    {
      "type": "function",
      "function": {
        "name": "create_connection",
        "description": "Crea o añade una nueva conexión SSH vacía en la aplicación",
        "parameters": {
          "type": "object",
          "properties": {},
          "required": []
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "delete_connection",
        "description": "Borra o elimina una conexión SSH existente dado su nombre",
        "parameters": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "El nombre exacto de la conexión que el usuario quiere borrar"
            }
          },
          "required": ["name"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "connect_connection",
        "description": "Conecta, activa o enciende una conexión SSH existente dado su nombre",
        "parameters": {
          "type": "object",
          "properties": {
            "name": {"type": "string", "description": "El nombre exacto de la conexión que se quiere encender o conectar"}
          },
          "required": ["name"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "disconnect_connection",
        "description": "Desconecta o apaga una conexión SSH existente dado su nombre",
        "parameters": {
          "type": "object",
          "properties": {
            "name": {"type": "string", "description": "El nombre exacto de la conexión que se quiere apagar o desconectar"}
          },
          "required": ["name"]
        }
      }
    }
  ];

  final Map<String, String> _systemPrompt = {
    'role': 'system',
    'content': 'Eres un asistente integrado en una app de túneles SSH. Usa las herramientas proporcionadas si el usuario te pide crear o borrar conexiones. Responde de forma amigable y concisa en español.'
  };

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _msgController.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();

    final url = Uri.parse('http://127.0.0.1:11434/api/chat');

    try {
      final requestMessages = [_systemPrompt, ..._messages];

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3.2', 
          'messages': requestMessages, 
          'tools': _tools,
          'stream': false, 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messageData = data['message'];
        
        String aiContent = "";

        // COMPROBAMOS SI OLLAMA HA DECIDIDO USAR UNA HERRAMIENTA 
        if (messageData['tool_calls'] != null && (messageData['tool_calls'] as List).isNotEmpty) {
          
          
          for (var toolCall in messageData['tool_calls']) {
            final functionName = toolCall['function']['name'];
            final arguments = toolCall['function']['arguments'];

            if (functionName == 'create_connection') {
              widget.onCreateConnection(); 
              aiContent += "¡Hecho! He creado una nueva conexión en blanco para ti.\n";
            } 
            else if (functionName == 'delete_connection') {
              final nameToDelete = arguments['name'];
              widget.onDeleteConnection(nameToDelete); 
              aiContent += "He mandado la orden para borrar la conexión llamada '$nameToDelete'.\n";
            }
            else if (functionName == 'connect_connection') {
              final nameToConnect = arguments['name'];
              widget.onConnectConnection(nameToConnect); 
              aiContent += "He iniciado el proceso para conectar '$nameToConnect'. Revisa si necesitas introducir la contraseña en la pantalla.\n";
            }
            else if (functionName == 'disconnect_connection') {
              final nameToDisconnect = arguments['name'];
              widget.onDisconnectConnection(nameToDisconnect); 
              aiContent += "He apagado la conexión de '$nameToDisconnect'.\n";
            }
          }
        } 
        else {
          
          aiContent = messageData['content'] ?? "No tengo respuesta.";
        }

        setState(() {
          _messages.add({'role': 'assistant', 'content': aiContent.trim()});
        });

      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error del servidor Ollama: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error de conexión. ¿Está Ollama ejecutándose? Detalle: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PARTE VISUAL DEL CHAT
    return Container(
      color: const Color.fromARGB(255, 245, 245, 245),
      child: Column(
        children: [
          // CABECERA DEL CHAT
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color.fromARGB(255, 50, 50, 50),
            width: double.infinity,
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ollama',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16, height: 16, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
              ],
            ),
          ),
          
          // ZONA DE MENSAJES
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? const Color.fromARGB(255, 212, 64, 96) 
                          : Colors.white, 
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        if (!isUser) 
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // CAJA DE TEXTO INFERIOR
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: _isLoading ? 'La IA está pensando...' : 'Pregunta a Ollama...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade400)
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : const Color.fromARGB(255, 212, 64, 96),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}