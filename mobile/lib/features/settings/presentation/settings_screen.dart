import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_ext.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = AppSettingsScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ──
          _SectionTitle(text: l10n.appearance),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                    color: AppColors.accent,
                  ),
                  title: Text(l10n.darkMode),
                  subtitle: Text(l10n.darkModeSubtitle),
                  value: _settings.themeMode == ThemeMode.dark,
                  activeTrackColor: AppColors.accent,
                  onChanged: (value) {
                    _settings.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Language ──
          _SectionTitle(text: l10n.language),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                RadioGroup<Locale>(
                  groupValue: _settings.locale,
                  onChanged: (locale) {
                    if (locale != null) _settings.setLocale(locale);
                  },
                  child: Column(
                    children: [
                      RadioListTile<Locale>(
                        value: const Locale('en'),
                        title: Text(l10n.english),
                      ),
                      const Divider(height: 1, indent: 16),
                      RadioListTile<Locale>(
                        value: const Locale('vi'),
                        title: Text(l10n.vietnamese),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── About ──
          _SectionTitle(text: l10n.about),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.accent),
              title: Text(l10n.version),
              trailing: Text(
                '0.1.0',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
