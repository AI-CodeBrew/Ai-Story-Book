import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/crash_log_service.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = '${info.version} (${info.buildNumber})');
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'fynktech@gmail.com',
      query: 'subject=${Uri.encodeComponent('FairyTale AI feedback')}',
    );
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No email app found on this device.', style: GoogleFonts.nunito())),
      );
    }
  }

  Future<void> _showCrashLog() async {
    final entries = await CrashLogService.getEntries();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Error Log', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (entries.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await CrashLogService.clear();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: Text('No errors recorded.', style: GoogleFonts.nunito(color: AppColors.textSecondary)))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) => Text(
                        entries[index],
                        style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This permanently deletes your account and every story you\'ve created. This cannot be undone.'),
              const SizedBox(height: 16),
              Text('Type DELETE to confirm:', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              TextField(controller: controller, onChanged: (_) => setDialogState(() {}), autofocus: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: controller.text.trim() == 'DELETE' ? () => Navigator.pop(context, true) : null,
              child: Text('Delete forever', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount();
    if (!context.mounted) return;
    if (ok) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account. Please try again.', style: GoogleFonts.nunito())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            _SettingsTile(
              icon: Icons.mail_outline,
              title: 'Send Feedback',
              subtitle: 'Report a bug or share an idea',
              onTap: _sendFeedback,
            ),
            _SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Error Log',
              subtitle: 'Recent in-app errors, kept on this device only',
              onTap: _showCrashLog,
            ),
            const Divider(height: 32),
            ListTile(
              title: Text('App Version', style: GoogleFonts.nunito(color: AppColors.textSecondary)),
              trailing: Text(_version, style: GoogleFonts.nunito(color: AppColors.textSecondary)),
            ),
            const Divider(height: 32),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all your stories',
              iconColor: AppColors.error,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: iconColor)),
      subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}
