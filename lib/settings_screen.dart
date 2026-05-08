import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'app_localizations.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool _isNotificationOn = true;
  bool _isDarkModeOn = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, s),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.language,
                        title: s.language,
                        trailing: Text(
                          localeProvider.locale.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        onTap: () => _showLanguagePicker(context, s, localeProvider),
                      ),

                      const SizedBox(height: 16),

                      _buildSettingTile(
                        icon: Icons.notifications_none_outlined,
                        title: s.notification,
                        trailing: CupertinoSwitch(
                          value: _isNotificationOn,
                          activeTrackColor: const Color(0xFF2962FF),
                          onChanged: (bool value) {
                            setState(() {
                              _isNotificationOn = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildSettingTile(
                        icon: Icons.dark_mode_outlined,
                        title: s.darkMode,
                        trailing: CupertinoSwitch(
                          value: _isDarkModeOn,
                          activeTrackColor: const Color(0xFF2962FF),
                          onChanged: (bool value) {
                            setState(() {
                              _isDarkModeOn = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppStrings s, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.selectLanguage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(s.english),
                trailing: localeProvider.locale == 'en'
                    ? const Icon(Icons.check_circle, color: Color(0xFF1A56F6))
                    : null,
                onTap: () {
                  localeProvider.setLocale('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text(s.vietnamese),
                trailing: localeProvider.locale == 'vi'
                    ? const Icon(Icons.check_circle, color: Color(0xFF1A56F6))
                    : null,
                onTap: () {
                  localeProvider.setLocale('vi');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN ---

  Widget _buildAppBar(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              s.settings,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Hàm tạo từng thanh Setting linh hoạt
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing, // Widget nằm ở góc phải (có thể là Text hoặc Switch)
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Hiển thị phần đuôi (Text "EN" hoặc Nút gạt Switch)
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFF3F8FF),
            Colors.white,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}