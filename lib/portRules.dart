import 'package:flutter/material.dart';
import 'package:xssh/inputPers.dart';

class PortRule {
  String name;
  String localPort;
  String destHost;
  String destPort;

  PortRule({
    this.name = '',
    this.localPort = '',
    this.destHost = '',
    this.destPort = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'localPort': localPort,
    'destHost': destHost,
    'destPort': destPort,
  };

  static PortRule fromJson(Map<String, dynamic> json) {
    return PortRule(
      name: json['name'] ?? '',
      localPort: json['localPort'] ?? '',
      destHost: json['destHost'] ?? '',
      destPort: json['destPort'] ?? '',
    );
  }
}

class PortRules extends StatelessWidget {
  final List<PortRule> rules;
  final void Function() onAddRule;
  final void Function(int) onRemoveRule;

  const PortRules({
    super.key,
    required this.rules,
    required this.onAddRule,
    required this.onRemoveRule,
  });

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
            const Text(
              'PORT FORWARDING RULES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            // LISTA SCROLLEABLE
            Expanded(
              child: ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Nombre
                        SizedBox(
                          width: 120,
                          child: TextField(
                            decoration: darkInput('Name'),
                            onChanged: (v) => rule.name = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('Local'), 
                        const SizedBox(width: 16),

                        // Local port
                        SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: darkInput('1234'),
                            onChanged: (v) => rule.localPort = v,
                          ),
                        ),
                        const SizedBox(width: 16),

                        const Text('→'),

                        const SizedBox(width: 16),

                        // Dest host
                        SizedBox(
                          width: 150,
                          child: TextField(
                            decoration: darkInput('Host'),
                            onChanged: (v) => rule.destHost = v,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Dest port
                        SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: darkInput('Port'),
                            onChanged: (v) => rule.destPort = v,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Botón borrar
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => onRemoveRule(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // BOTÓN AÑADIR
            ElevatedButton.icon(
              onPressed: onAddRule,
              icon: const Icon(Icons.add),
              label: const Text('Add rule'),
            ),
          ],
        ),
      ),
    );
  }
}
