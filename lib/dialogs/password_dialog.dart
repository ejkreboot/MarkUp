import 'package:flutter/material.dart';

class PasswordDialogResult {
  final String password;
  final bool rememberPassword;

  PasswordDialogResult({required this.password, required this.rememberPassword});
}

Future<PasswordDialogResult?> showPasswordDialog(
  BuildContext context, {
  String? initialPassword,
}) async {
  final TextEditingController controller = TextEditingController(text: initialPassword ?? '');
  bool rememberPassword = true;
  return showDialog<PasswordDialogResult?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter reMarkable Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: rememberPassword,
                  onChanged: (bool? value) {
                    rememberPassword = value ?? true;
                    // Force rebuild so the checkbox reflects the change
                    (context as Element).markNeedsBuild();
                  },
                ),
                const Text('Remember password'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = controller.text.trim();
              if (password.isNotEmpty) {
                Navigator.of(context).pop(PasswordDialogResult(
                  password: password,
                  rememberPassword: rememberPassword,
                ));
              }
            },
            child: const Text('Connect'),
          ),
        ],
      );
    },
  );
}
