import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nix/providers/lyrics_provider.dart';
import 'package:provider/provider.dart';

class LyricSettingsPage extends StatelessWidget {
  const LyricSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LyricSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lyrics Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: settings.loaded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom LRCLIB URL (optional)'),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: Text(
                        settings.isCustomLrcLibSet
                            ? settings.lrcLibBaseUrl
                            : 'Not set — using built-in lyrics lookup',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: settings.isCustomLrcLibSet
                          ? const Text('Custom LRCLIB configured')
                          : const Text('No custom instance configured'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditDialog(context, settings);
                          } else if (value == 'clear') {
                            await settings.clearLrcLibBaseUrl();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('LRCLIB URL cleared'),
                              ),
                            );
                          } else if (value == 'test') {
                            final ok = await _testConnection(
                              settings.lrcLibBaseUrl,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? 'Connection OK' : 'Connection failed',
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'test',
                            child: Text('Test connection'),
                          ),
                          if (settings.isCustomLrcLibSet)
                            const PopupMenuItem(
                              value: 'clear',
                              child: Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Notes:'),
                  const SizedBox(height: 8),
                  const Text(
                    '• Provide a base URL like https://example.com\n'
                    '• Nix will query <base>/lyrics?q=<song title>\n'
                    '• Leave empty to use built-in lookup (lower legal risk for you).',
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, settings),
        label: const Text('Set LRCLIB URL'),
        icon: const Icon(Icons.link),
      ),
    );
  }

  void _showEditDialog(BuildContext context, LyricSettingsProvider settings) {
    final formKey = GlobalKey<FormState>();
    String input = settings.lrcLibBaseUrl;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Configure LRCLIB URL'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: input,
            decoration: const InputDecoration(
              hintText: 'https://your-lrclib.example.com',
            ),
            keyboardType: TextInputType.url,
            onChanged: (v) => input = v,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final ok = settings.validateUrl(v);
              return ok ? null : 'Enter a valid http or https URL';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                await settings.setLrcLibBaseUrl(input);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('LRCLIB URL saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () async {
              if (input.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a URL to test')),
                );
                return;
              }
              if (!settings.validateUrl(input)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
                return;
              }
              final ok = await _testConnection(input);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'OK' : 'Connection failed')),
              );
            },
            child: const Text('Quick Test'),
          ),
        ],
      ),
    );
  }

  Future<bool> _testConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
