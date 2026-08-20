import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/shared/providers/theme_provider.dart';

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const SettingsSheet(),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.purpleMid,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.purpleLight.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Settings',
            style: TextStyle(
              color: colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // Appearance Section
          _buildSectionHeader('Appearance', colors),
          const SizedBox(height: 8),
          _buildSettingRow(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Toggle dark or light theme interface',
            colors: colors,
            trailing: Switch(
              value: themeProvider.isDarkMode,
              activeThumbColor: colors.purpleLight,
              activeTrackColor: colors.purpleAccent.withAlpha(102),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: colors.purpleDark.withAlpha(77),
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Preferences Section
          _buildSectionHeader('Preferences', colors),
          const SizedBox(height: 8),
          _buildSettingRow(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive booking and promo updates',
            colors: colors,
            trailing: Switch(
              value: _notificationsEnabled,
              activeThumbColor: colors.purpleLight,
              activeTrackColor: colors.purpleAccent.withAlpha(102),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: colors.purpleDark.withAlpha(77),
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'शॉटCUT Salon App',
                  style: TextStyle(
                    color: colors.purpleLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Production)',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors colors) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: colors.purpleLight,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeColors colors,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.purpleDark.withAlpha(102),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.purpleLight.withAlpha(26)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.purpleAccent.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.purpleLight, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
