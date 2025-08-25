import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:nix/%20utils/translator.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(t(context, 'choose_language')),
        actions: [
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Help"),
                content: Text(
                  "if you confused about (en), That's mean the Country of short name",
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Okay"),
                  ),
                ],
              ),
            ),
            icon: Icon(FlutterRemix.information_line),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            _languageTile(context, 'Burmese (my)', 'bur', provider),
            _languageTile(context, 'English (us) Deafault', 'en', provider),
            _languageTile(context, 'Falam (my)', 'falam', provider),
            _languageTile(context, 'Hakha (my)', 'hakha', provider),
          ],
        ),
      ),
    );
  }

  Widget _languageTile(
    BuildContext context,
    String title,
    String code,
    LanguageProvider provider,
  ) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      title: Text(title),
      trailing: provider.currentLanguage == code
          ? const Icon(FlutterRemix.check_fill)
          : null,
      onTap: () {
        provider.setLanguage(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You've change language as $title")),
        );
      },
    );
  }
}
