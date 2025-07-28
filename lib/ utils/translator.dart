// utils/translator.dart
import 'languages.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:flutter/material.dart';

String t(BuildContext context, String key) {
  final lang = Provider.of<LanguageProvider>(
    context,
    listen: false,
  ).currentLanguage;
  return appTranslations[lang]?[key] ?? key;
}
