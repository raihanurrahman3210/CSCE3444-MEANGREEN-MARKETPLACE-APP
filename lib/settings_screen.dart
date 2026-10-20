import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  Future<void> changeName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController();

    try {
      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      controller.text =
          (profile?['display_name'] ?? user.userMetadata?['full_name'] ?? '')
              .toString();

      if (!mounted) return;

      final newName = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Change Name'),
            content: TextField(
              controller: controller,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(dialogContext, name);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (newName == null) return;

      final updated = await supabase
          .from('profiles')
          .update({'display_name': newName})
          .eq('id', user.id)
          .select('id');

      if (updated.isEmpty) {
        throw Exception('Your profile record was not found.');
      }

      await supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update name: $error')));
    } finally {
      controller.dispose();
    }
  }

  void showAccountInfo() {
    final user = supabase.auth.currentUser;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Account Information'),
          content: Text(
            user == null
                ? 'You are not logged in.'
                : 'Email: ${user.email ?? "Not available"}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void contactUs() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Contact Us'),
          content: const Text(
            'Have a question or need assistance with MeanGreen Marketplace?\n\n'
            'Please contact us at abir3210rh@icloud.com for any questions, '
            'concerns, or technical issues. We will do our best to assist you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not log out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: showAccountInfo,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Change Name'),
            trailing: const Icon(Icons.chevron_right),
            onTap: changeName,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.contact_support_outlined),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: contactUs,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
